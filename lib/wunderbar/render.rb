unless defined? Sinatra
  raise RuntimeError.new('Sinatra is a prereq for wunderbar/render')
  # a parallel solution is possible for Rails, but that work hasn't
  # been done yet
end

require 'wunderbar/sinatra'
require 'wunderbar/script'
require 'nokogumbo'

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
    options = Wunderbar::Render::RUBY2JS_OPTIONS.merge(scope: @_scope)
    common = Ruby2JS.convert(block, options)
    server = Wunderbar::Render.server(common)
    client = Wunderbar::Render.client(common, element, target)

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
    setup = []
    requires = {}
    browserify = false
    Wunderbar::Asset.scripts.each do |script|
      next unless script.options[:render]
      setup += script.options[:render] if Array === script.options[:render]
      requires.merge! script.options[:require] if script.options[:require]
      browserify = true if script.options[:browserify]

      if script.contents
        scripts.unshift script.contents
      elsif script.path
        if script.path.start_with? '/'
          path = (ENV['DOCUMENT_ROOT'] + script.path).untaint
        else
          path = File.expand_path(script.path, Wunderbar::Asset.root)
        end
        setup << File.read(script.options[:server] || path)
      end
    end

    # concatenate and execute scripts on server
    if browserify
      setup += requires.map {|key, value| 
        "const #{key}=module.exports.#{key} || require(#{value.inspect})"
      }
    end
    scripts.unshift *setup.uniq
    html = Wunderbar::Render.eval(scripts, server)

    # insert results into target
    nodes = builder._ { html }

    begin
      if nodes.length == 1
        nodes.each {|node| node.parent = target}
        target.children += nodes
      else
        span = Wunderbar::Node.new('span')
        nodes.each {|node| node.parent = span}
        span.children += nodes
        target.children << span
      end
    rescue => e
      span = Wunderbar::Node.new('span',
        style: 'background-color:#ff0; margin: 1em 0; padding: 1em; ' +
               'border: 4px solid red; border-radius: 1em')
      span.children << Wunderbar::Node.new('pre', e.to_s)
      span.children << Wunderbar::Node.new('pre', e.backtrace.join("\n"))
      span.children << Wunderbar::Node.new('pre', html)
      span.children << Wunderbar::Node.new('pre', nodes.inspect)
      span.children.each {|node| node.parent = span}
      target.children << span
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

  etag js.etag

  response.headers['SourceMap'] = "#{script}.js.map"

  # if query string is passed, mark as immutable and expiring in a year
  if env['QUERY_STRING']
    expires 31536000
    cache_control :public, :immutable, max_age: 31536000
  end

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
