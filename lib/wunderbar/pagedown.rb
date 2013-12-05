require 'wunderbar'

source = File.expand_path('../vendor/Markdown.Converter.js', __FILE__)

Wunderbar::Asset.script name: 'Markdown.Converter.js', file: source
