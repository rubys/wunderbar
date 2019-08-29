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
spec = eval File.read('wunderbar.gemspec')

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

namespace :vendor do
  task :vue do
    # [sudo] npm install -g browserify
    # [sudo] npm install -g uglify-es
    sh 'npm update --no-save'
    sh 'curl -s -S https://vuejs.org/js/vue.min.js > ' +
      'lib/wunderbar/vendor/vue.min.js'
    sh 'browserify -r vue -r ./data/vue-render.js:vue-server | uglifyjs >' +
      'lib/wunderbar/vendor/vue-server.min.js'
  end
end

# If you don't want to generate the .gemspec file, just remove this line. Reasons
# why you might want to generate a gemspec:
#  - using bundler with a git source
#  - building the gem without rake (i.e. gem build blah.gemspec)
#  - maybe others?
task :package => :gem

require 'rake/clean'
CLOBBER.include FileList.new('pkg')
Rake::Task[:clobber_package].clear
CLOBBER.existing!

