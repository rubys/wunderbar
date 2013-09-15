require 'wunderbar'

source = Dir[File.expand_path('../jquery-*.min.js', __FILE__)].
  sort_by {|name| name[/-([.\d]*)\.min.js$/,1].split('.').map(&:to_i)}.last

Wunderbar::Asset.script :name => 'jquery-min.js', :file => source
