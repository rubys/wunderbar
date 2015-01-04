require "rubygems/package_task"

require File.expand_path(File.dirname(__FILE__) + "/lib/wunderbar/version")
require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/test*.rb"]
  t.verbose = true
end

task :push => %w(clean test package) do
  sh 'git push origin master'
  sh "gem push #{Dir['pkg/*.gem'].last}"
end

task :default => ["test"]

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

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
    (utf-8), consistently indented, readable applications.  This includes
    output that conforms to the Polyglot specification and the emerging
    results from the XML Error Recovery Community Group.
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

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more 
# about that here: http://gemcutter.org/pages/gem_docs
Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

file "#{spec.name}.gemspec" => [:gemspec]

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# If you don't want to generate the .gemspec file, just remove this line. Reasons
# why you might want to generate a gemspec:
#  - using bundler with a git source
#  - building the gem without rake (i.e. gem build blah.gemspec)
#  - maybe others?
task :package => :gemspec

require 'rake/clean'
CLOBBER.include FileList.new('pkg')
Rake::Task[:clobber_package].clear
CLOBBER.existing!

