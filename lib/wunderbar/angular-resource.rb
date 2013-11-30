require 'wunderbar/angularjs'
require 'ruby2js/filter/angular-resource'

source = File.expand_path('../angular-resource.min.js', __FILE__)

Wunderbar::Asset.script :name => 'angular-resource.min.js', :file => source
