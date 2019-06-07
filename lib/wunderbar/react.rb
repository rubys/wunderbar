require 'wunderbar/render'
require 'ruby2js/filter/react'
require 'execjs'

react = File.expand_path('../vendor/react-with-addons.min.js', __FILE__)
Wunderbar::Asset.script name: 'react-min.js', file: react, render: true

reactdom = File.expand_path('../vendor/react-dom.min.js', __FILE__)
Wunderbar::Asset.script name: 'react-dom.min.js', file: reactdom, render: true,
  server: File.expand_path('../vendor/react-dom-server.min.js', __FILE__)

class Wunderbar::Render
  RUBY2JS_OPTIONS = {react: true}

  def self.server(common)
    "ReactDOMServer.renderToString(#{common})"
  end

  # return all nodes on server rendering, as there is no wrapper element
  # like there is for vue
  def self.extract(nodes)
    nodes
  end

  def self.client(common, element, target)
    "ReactDOM.render(#{common}, #{element})"
  end

  def self.eval(scripts, server)
    context = ExecJS.compile(scripts.compact.join(";\n"))
    context.eval(server)
  rescue ExecJS::ProgramError => e
    Wunderbar.error e
    "<pre>" + e.message.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;') +
      "</pre>"
  end
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
