require 'wunderbar/jquery'

source = File.expand_path('../vendor/bootstrap.min.js', __FILE__)
Wunderbar::Asset.script name: 'bootstrap-min.js', file: source

source = File.expand_path('../vendor/bootstrap.min.css', __FILE__)
Wunderbar::Asset.css name: 'bootstrap-min.css', file: source
