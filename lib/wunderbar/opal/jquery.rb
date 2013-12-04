require 'wunderbar/opal'
require 'wunderbar/jquery'
require 'opal-jquery'

Wunderbar::Asset.script :name => 'opal-jquery.js',
  :contents => Opal::Builder.build('opal-jquery')
