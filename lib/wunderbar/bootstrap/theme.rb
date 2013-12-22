require 'wunderbar/bootstrap'

source = File.expand_path('../../vendor/bootstrap-theme.min.css', __FILE__)

Wunderbar::Asset.css name: 'bootstrap-theme.min.css', file: source
