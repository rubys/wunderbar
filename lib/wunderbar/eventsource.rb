require 'wunderbar'

source = File.expand_path('../vendor/eventsource.min.js', __FILE__)

Wunderbar::Asset.script name: 'eventsource.min.js', file: source
