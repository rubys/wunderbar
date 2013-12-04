require 'wunderbar/opal'
require 'opal/browser'

Wunderbar::Asset.script :name => 'opal-browser.js',
  :contents => Opal::Builder.build('browser')
