require 'wunderbar'
require 'ruby2js/filter/angularrb'

source = File.expand_path('../angular.min.js', __FILE__)

Wunderbar::Asset.script :name => 'angular-min.js', :file => source

module Wunderbar
  class HtmlMarkup
    def _script(*args, &block)
      if block
        args.unshift Ruby2JS.convert(block, 
          filters: [Ruby2JS::Filter::AngularRB])
        super *args, &nil
      else
        super
      end
    end
  end
end
