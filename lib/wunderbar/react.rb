unless defined? Sinatra
  raise RuntimeError.new('Sinatra is a prereq for wunderbar/react')
  # a parallel solution is possible for Rails, but that work hasn't
  # been done yet
end

require 'wunderbar/sinatra'
require 'wunderbar/script'
require 'ruby2js/filter/react'
require 'execjs'
require 'nokogumbo'

source = Dir[File.expand_path('../vendor/react-*.min.js', __FILE__)].
  sort_by {|name| name[/-v?([.\d]*)\.min.js$/,1].split('.').map(&:to_i)}.last

Wunderbar::Asset.script name: 'react-min.js', file: source,
  react: ['global=this']

class Wunderbar::ClientScriptNode < Wunderbar::ScriptNode
end

class Wunderbar::XmlMarkup
  def render(container, &block)
    csspath = Wunderbar::Node.parse_css_selector(container)
    root = @node.root

    # find the scripts and target on the page
    scripts = root.search('script')
    target = root.at(container)

    # compute base
    base = root.at('base')
    base = (base ? base.attrs[:href] : nil) || '/'
    base = base[1..-1] if base.start_with? '/'

    # compute client side container
    element = "document.querySelector(#{container.inspect})"
    if csspath.length == 1 and csspath[0].length == 1
      value = csspath[0].values.first
      case csspath[0].keys.first
      when :id
        element = "document.getElementById(#{value.inspect})"
      when :class
        value = value.join(' ')
        element = "document.getElementsByClassName(#{value.inspect})[0]"
      when :name
        element = "document.getElementsByTagName(#{value.inspect})[0]"
      end
    end

    # build client and server scripts
    common = Ruby2JS.convert(block, scope: @_scope, react: true)
    server = "React.renderToString(#{common})"
    client = "React.render(#{common}, #{element})"

    # extract content of scripts
    scripts.map! do |script|
      result = nil
      next if Wunderbar::ClientScriptNode === script

      if script.attrs[:src]
        src = File.join(base, script.attrs[:src])
        name = File.expand_path(src, @_scope.settings.public_folder.untaint)
        if File.exist? name
          result = File.read(name)
        else
          name = File.expand_path(src+'.rb', @_scope.settings.views.untaint)
          if File.exist? name
            result = Ruby2JS.convert(File.read(name), file: name)
          end
        end
      else
        result = Ruby2JS.convert(script.block, binding: script.binding)
      end

      result
    end

    builder = Wunderbar::HtmlMarkup.new({})
    begin
      setup = []
      Wunderbar::Asset.scripts.each do |script|
        next unless script.options[:react]
        setup += script.options[:react] if Array === script.options[:react]

        if script.contents
          scripts.unshift script.contents
        elsif script.path
          scripts.unshift File.read(
            File.expand_path(script.path, Wunderbar::Asset.root))
        end
      end

      # concatenate and execute scripts on server
      scripts.unshift *setup.uniq
      context = ExecJS.compile(scripts.compact.join(";\n"))

      # insert results into target
      nodes = builder._ { context.eval(server) }
      nodes.each {|node| node.parent = target}
      target.children += nodes
    rescue ExecJS::ProgramError => e
      target.children << builder._pre(e.message).node?
    end

    # add client side script
    tag! 'script', Wunderbar::ClientScriptNode, client
  end
end

get %r{^/([-\w]+)\.js$} do |script|
  _js :"#{script}"
end

SCRIPTS = {}
get %r{^/([-\w]+)\.js.map$} do |script|
  if not SCRIPTS[script]
    file = File.join(Sinatra::Application.views, "#{script}.js.rb")
    pass unless File.exist? file
    SCRIPTS[script] = Ruby2JS.convert(File.read(file), file: file)
  end

  sourcemap = SCRIPTS[script].sourcemap

  content_type 'application/json;charset:utf8'
  sourcemap[:file] = sourcemap[:file].sub Sinatra::Application.views, ''
  sourcemap[:sources] = 
    sourcemap[:sources].map {|source| source.sub Sinatra::Application.views, ''}
  JSON.pretty_generate sourcemap
end

# Monkeypatch to address https://github.com/sstephenson/execjs/pull/180
require 'execjs'
class ExecJS::ExternalRuntime::Context
  alias_method :w_write_to_tempfile, :write_to_tempfile
  def write_to_tempfile(*args)
    tmpfile = w_write_to_tempfile(*args).path.untaint
    tmpfile = Struct.new(:path, :to_str).new(tmpfile, tmpfile)
    def tmpfile.unlink
      File.unlink path
    end
    tmpfile
  end
end
