require 'wunderbar/script'
require 'ruby2js/filter/angularrb'

source = File.expand_path('../vendor/angular.min.js', __FILE__)

Wunderbar::Asset.script :name => 'angular-min.js', :file => source
