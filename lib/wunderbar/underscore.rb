require 'wunderbar/script'
require 'ruby2js/filter/underscore'
require 'ruby2js/filter/functions'

source = File.expand_path('../vendor/underscore-min.js', __FILE__)
Wunderbar::Asset.script :name => 'underscore-min.js', :file => source
