require 'rubygems'
require 'rake'
require 'echoe'

require File.expand_path(File.dirname(__FILE__) + "/lib/cgi-spa/version")

Echoe.new('cgi-spa', CgiSpa::VERSION::STRING) do |p|
  p.summary    = "CGI Single Page Applications"
  p.description    = <<-EOF
    Provides a number of globals, helper methods, and monkey patches which
    simplify the development of single page applications in the form of
    CGI scripts.
  EOF
  p.url            = "http://github.com/rubys/cgi-spa"
  p.author         = "Sam Ruby"
  p.email          = "rubys@intertwingly.net"
  p.dependencies   = %w(
    builder
    json
  )
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test*.rb']
end
