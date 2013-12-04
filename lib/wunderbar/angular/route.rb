require 'wunderbar/angularjs'
require 'ruby2js/filter/angular-route'

source = File.expand_path('../../vendor/angular-route.min.js', __FILE__)

Wunderbar::Asset.script :name => 'angular-route.min.js', :file => source
