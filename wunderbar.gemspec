# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'wunderbar/version'

Gem::Specification.new do |s|

  # Change these as appropriate
  s.name           = "wunderbar"
  s.license        = 'MIT'
  s.version        = Wunderbar::VERSION::STRING
  s.summary        = "HTML Generator and CGI application support"
  s.author         = "Sam Ruby"
  s.email          = "rubys@intertwingly.net"
  s.homepage       = "http://github.com/rubys/wunderbar"
  s.description    = <<-EOD
    Wunderbar makes it easy to produce valid HTML5, wellformed XHTML, Unicode
    (utf-8), consistently indented, readable applications.'
  EOD

  # Add any extra files to include in the gem
  s.files             = %w(wunderbar.gemspec README.md COPYING) + Dir.glob("{lib}/**/*")
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  s.add_dependency("json")

  # If your tests use any gems, include them here
  # s.add_development_dependency("mocha") # for example

  # Require Ruby 1.9.3 or greater
  s.required_ruby_version = '>= 1.9.3'
end
