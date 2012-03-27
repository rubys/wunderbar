require 'rubygems'
require 'rake'
require 'echoe'

require File.expand_path(File.dirname(__FILE__) + "/lib/wunderbar/version")

mkdir_p 'pkg' unless File.exist? 'pkg'

Echoe.new('wunderbar', Wunderbar::VERSION::STRING) do |p|
  p.summary    = "HTML Generator and CGI application support"
  p.description    = <<-EOF
    Wunderbar makes it easy to produce valid HTML5, wellformed XHTML, Unicode
    (utf-8), consistently indented, readable applications.  This includes
    output that conforms to the Polyglot specification and the emerging
    results from the XML Error Recovery Community Group.
  EOF
  p.url            = "http://github.com/rubys/wunderbar"
  p.author         = "Sam Ruby"
  p.email          = "rubys@intertwingly.net"
  p.dependencies   = %w(
    builder
    json
  )
end
