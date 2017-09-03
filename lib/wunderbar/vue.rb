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
    @nodejs = `which nodejs`.chomp
    @nodejs = `which node`.chomp if @nodejs.empty?
    raise RuntimeError.new('Unable to locate nodejs') if @nodejs.empty?
    @nodejs.untaint
  end

  def self.server(common)
    "VueServer.renderToString(new Vue({render: function($h) {return #{common}}}))"
  end

  def self.client(common, element, target)
    wrap = "$h(#{target.name.inspect}, " +
      "{attrs: {#{target.attrs.map {|name, value|
      "#{name}: #{value.inspect}"}.join(' ')}}}, [#{common}])"
    "new Vue({el: #{element}, render: function($h) {return #{wrap}}})"
  end

  def self.eval(scripts, server)
    output, status = Open3.capture3 self.nodejs,
      stdin_data: scripts.compact.join(";\n") + ";\n" + server
    output.untaint
  rescue => e
    Wunderbar.error e
    "<pre>" + e.message.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;') +
      "</pre>"
  end
end
