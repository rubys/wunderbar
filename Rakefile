require 'rubygems'
require 'rake'
require 'echoe'

require File.expand_path(File.dirname(__FILE__) + "/lib/wunderbar/version")

mkdir_p 'pkg' unless File.exist? 'pkg'

Echoe.new('wunderbar', Wunderbar::VERSION::STRING) do |p|
  p.summary    = "HTML Generator and CGI application support"
  p.description    = <<-EOF
    Provides a number of globals, helper methods, and monkey patches which
    simplify the generation of HTML and the development of CGI scripts.
  EOF
  p.url            = "http://github.com/rubys/wunderbar"
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
