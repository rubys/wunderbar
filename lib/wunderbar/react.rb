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

Wunderbar::Asset.script :name => 'react-min.js', :file => source

class Wunderbar::XmlMarkup
  def render(container, &block)
    csspath = Wunderbar::Node.parse_css_selector(container)
    root = @node.root

    # find the scripts and target on the page
    scripts = root.search('script')
    target = root.at(container)

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
        element = "document.getElementsByName(#{value.inspect})[0]"
      end
    end

    # build client and server scripts
    common = Ruby2JS.convert(block, scope: @_scope)
    server = "React.renderToString(#{common})"
    client = "React.render(#{common}, #{element})"

    # extract content of scripts
    scripts.map! do |script|
      result = nil

      if script.attrs[:src]
        src = script.attrs[:src]
        name = File.join(@_scope.settings.public_folder.untaint, src)
        if File.exist? name
          result = File.read(name)
        else
          name = File.join(@_scope.settings.views.untaint, src+'.rb')
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
      # concatenate and execute scripts on server
      scripts = ['global=this'] + Wunderbar::Asset.scripts + scripts
      context = ExecJS.compile(scripts.compact.join(";\n"))

      # insert results into target
      nodes = builder._ { context.eval(server) }
      nodes.each {|node| node.parent = target}
      target.children += nodes
    rescue ExecJS::ProgramError => e
      target.children << builder._pre(e.message).node?
    end

    # add client side script
    tag! 'script', Wunderbar::ScriptNode, client
  end
end

get %r{^/([-\w]+)\.js$} do |script|
  _js :"#{script}"
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
