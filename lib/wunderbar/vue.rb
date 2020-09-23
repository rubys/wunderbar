require 'wunderbar/render'
require 'ruby2js/filter/vue'

vue = File.expand_path('../vendor/vue.min.js', __FILE__)
Wunderbar::Asset.script name: 'vue.min.js', file: vue, render: true,
  server: File.expand_path('../vendor/vue-server.min.js', __FILE__),
  require: {Vue: 'vue', VueServer: 'vue-server'}, browserify: true

class Wunderbar::Render
  RUBY2JS_OPTIONS = {vue_h: '$h'}

  def self.nodejs
    return @nodejs if @nodejs
    path = `which nodejs`.chomp
    path = `which node`.chomp if path.empty?
    raise RuntimeError.new('Unable to locate nodejs') if path.empty?
    @nodejs = path
  end

  def self.server(common)
    "VueServer.renderToString(new Vue({render: function($h) {
      return $h('div', #{common})}}))"
  end

  # unwrap children from div wrapper inserted by self.server
  def self.extract(nodes)
    if 
      nodes.length == 1 and nodes.first.name == 'div' and
      nodes.first.attrs['data-server-rendered'].to_s == 'true'
    then
      nodes.first.children
    else
      nodes
    end
  end

  def self.client(common, element, target)
    wrap = "$h(#{target.name.inspect}, " +
      "{attrs: {#{target.attrs.map {|name, value|
      "#{name}: #{value.inspect}"}.join(', ')}}}, #{common})"
    "new Vue({el: #{element}, render: function($h) {return #{wrap}}})"
  end

  def self.eval(scripts, server)
    stdout, stderr, status = Open3.capture3 self.nodejs,
      stdin_data: scripts.compact.join(";\n") + ";\n" + server

    unless stderr.empty?
      Wunderbar.error stderr
      stdout += "\n<pre>#{CGI.escapeHTML(stderr)}</pre>"
    end

    stdout
  rescue => e
    Wunderbar.error e
    "<pre>#{CGI.escapeHTML(e.message)}</pre>"
  end
end
