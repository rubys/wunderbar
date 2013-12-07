require 'wunderbar'

unless defined? Opal
  begin
    require 'ruby2js/filter/jquery'
    require 'wunderbar/script'
  rescue LoadError
  end
end

source = Dir[File.expand_path('../vendor/jquery-*.min.js', __FILE__)].
  sort_by {|name| name[/-([.\d]*)\.min.js$/,1].split('.').map(&:to_i)}.last

Wunderbar::Asset.script :name => 'jquery-min.js', :file => source
