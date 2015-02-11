require 'wunderbar'

source = File.expand_path('../vendor/marked.min.js', __FILE__)

Wunderbar::Asset.script name: 'marked.min.js', file: source
