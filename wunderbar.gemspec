# -*- encoding: utf-8 -*-
# stub: wunderbar 1.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "wunderbar".freeze
  s.version = "1.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Ruby".freeze]
  s.date = "2019-06-07"
  s.description = "    Wunderbar makes it easy to produce valid HTML5, wellformed XHTML, Unicode\n    (utf-8), consistently indented, readable applications.'\n".freeze
  s.email = "rubys@intertwingly.net".freeze
  s.files = ["COPYING".freeze, "README.md".freeze, "lib/wunderbar".freeze, "lib/wunderbar.rb".freeze, "lib/wunderbar/asset.rb".freeze, "lib/wunderbar/backtick.rb".freeze, "lib/wunderbar/bootstrap".freeze, "lib/wunderbar/bootstrap.rb".freeze, "lib/wunderbar/bootstrap/theme.rb".freeze, "lib/wunderbar/builder.rb".freeze, "lib/wunderbar/cgi-methods.rb".freeze, "lib/wunderbar/coderay.rb".freeze, "lib/wunderbar/coffeescript.rb".freeze, "lib/wunderbar/cssproxy.rb".freeze, "lib/wunderbar/environment.rb".freeze, "lib/wunderbar/eventsource.rb".freeze, "lib/wunderbar/html-methods.rb".freeze, "lib/wunderbar/installation.rb".freeze, "lib/wunderbar/job-control.rb".freeze, "lib/wunderbar/jquery".freeze, "lib/wunderbar/jquery.rb".freeze, "lib/wunderbar/jquery/filter.rb".freeze, "lib/wunderbar/jquery/stupidtable.rb".freeze, "lib/wunderbar/listen.rb".freeze, "lib/wunderbar/logger.rb".freeze, "lib/wunderbar/markdown.rb".freeze, "lib/wunderbar/marked.rb".freeze, "lib/wunderbar/node.rb".freeze, "lib/wunderbar/pagedown.rb".freeze, "lib/wunderbar/polymer.rb".freeze, "lib/wunderbar/rack.rb".freeze, "lib/wunderbar/rails.rb".freeze, "lib/wunderbar/react.rb".freeze, "lib/wunderbar/render.rb".freeze, "lib/wunderbar/script.rb".freeze, "lib/wunderbar/server.rb".freeze, "lib/wunderbar/sinatra.rb".freeze, "lib/wunderbar/underscore.rb".freeze, "lib/wunderbar/vendor".freeze, "lib/wunderbar/vendor/Markdown.Converter.js".freeze, "lib/wunderbar/vendor/bootstrap-theme.min.css".freeze, "lib/wunderbar/vendor/bootstrap.min.css".freeze, "lib/wunderbar/vendor/bootstrap.min.js".freeze, "lib/wunderbar/vendor/eventsource.min.js".freeze, "lib/wunderbar/vendor/jquery-3.2.1.min.js".freeze, "lib/wunderbar/vendor/marked.min.js".freeze, "lib/wunderbar/vendor/polymer-v0.0.20131003.min.js".freeze, "lib/wunderbar/vendor/react-dom-server.min.js".freeze, "lib/wunderbar/vendor/react-dom.min.js".freeze, "lib/wunderbar/vendor/react-with-addons.min.js".freeze, "lib/wunderbar/vendor/stupidtable.min.js".freeze, "lib/wunderbar/vendor/underscore-min.js".freeze, "lib/wunderbar/vendor/vue-server.min.js".freeze, "lib/wunderbar/vendor/vue.min.js".freeze, "lib/wunderbar/version.rb".freeze, "lib/wunderbar/vue.rb".freeze, "lib/wunderbar/websocket.rb".freeze, "wunderbar.gemspec".freeze]
  s.homepage = "http://github.com/rubys/wunderbar".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.7.6".freeze
  s.summary = "HTML Generator and CGI application support".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
    else
      s.add_dependency(%q<json>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<json>.freeze, [">= 0"])
  end
end
