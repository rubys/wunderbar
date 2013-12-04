require 'wunderbar/jquery'

source = File.expand_path('../../vendor/stupidtable.min.js', __FILE__)

Wunderbar::Asset.script :name => 'stupidtable.min.js', :file => source
