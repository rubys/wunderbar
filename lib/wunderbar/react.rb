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

react = File.expand_path('../vendor/react-with-addons.min.js', __FILE__)

Wunderbar::Asset.script name: 'react-min.js', file: react, react: true

class Wunderbar::Asset
  @@cached_scripts = {}
  def self.convert(file)
    cached = @@cached_scripts[file]
    return cached if cached and cached.uptodate?
    return nil unless File.exist? file
    @@cached_scripts[file] = Ruby2JS.convert(File.read(file), file: file)
  end
end

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
    base = base && base.attrs[:href]
    base ||= @_scope.env['REQUEST_URI'][/.*\//]

    _base = @_scope.env['HTTP_X_WUNDERBAR_BASE']
    base = base[_base.length..-1] if _base and base.start_with? _base

    if base == '..' or base.end_with? '/..'
      base = (Pathname.new(@_scope.env['REQUEST_URI']) + '../' + base).to_s
    end

    script = @_scope.env['SCRIPT_NAME']
    base = base[script.length..-1] if script and base.start_with? script

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
        src = script.attrs[:src]

        src = File.join(base, src) if not base.empty?
        src.sub!(/\?.*$/, '') # strip queries (typically mtimes)
        src.untaint

        name = File.expand_path(src, @_scope.settings.public_folder.untaint)
        name.untaint unless src.tainted?
        if File.exist? name
          result = File.read(name)
        else
          file = File.expand_path(src+'.rb', @_scope.settings.views.untaint)
          result = Wunderbar::Asset.convert(file)
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
          if script.path.start_with? '/'
            path = (ENV['DOCUMENT_ROOT'] + script.path).untaint
          else
            path = File.expand_path(script.path, Wunderbar::Asset.root)
          end
          scripts.unshift File.read(path)
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
      Wunderbar.error e
      target.children << builder._pre(e.message).node?
    end

    # add client side script
    tag! 'script', Wunderbar::ClientScriptNode, client
  end
end

class Ruby2JS::Serializer
  def etag
    @etag ||= Digest::MD5.hexdigest(to_str)
  end

  def sourcemap_etag
    @sourcemap_etag ||= Digest::MD5.hexdigest(sourcemap.inspect)
  end
end

get %r{/([-\w]+)\.js} do |script|
  file = File.join(settings.views, "#{script}.js.rb")
  begin
    js = Wunderbar::Asset.convert(file)
    pass unless js
  rescue Exception => e
    Wunderbar.error e.to_s
    return [500, {'Content-type' => 'text/plain'}, "*** ERROR ***\n\n#{e}"]
  end

  response.headers['SourceMap'] = "#{script}.js.map"

  etag js.etag

  content_type 'application/javascript; charset=utf-8'

  js.to_s
end

get %r{/((?:\w+\/)*[-\w]+)\.js.rb} do |script|
  file = File.join(settings.views, "#{script}.js.rb")
  pass unless File.exist? file
  send_file file
end

get %r{/([-\w]+)\.js.map} do |script|
  file = File.join(settings.views, "#{script}.js.rb")
  js = Wunderbar::Asset.convert(file)
  pass unless js

  etag js.sourcemap_etag

  sourcemap = js.sourcemap

  content_type 'application/json;charset:utf8'
  base = settings.views + '/'
  sourcemap[:file] = sourcemap[:file].sub base, ''
  sourcemap[:sources].map! {|source| source.sub base, ''}
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
