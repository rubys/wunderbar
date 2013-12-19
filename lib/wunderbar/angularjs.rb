require 'wunderbar/script'
require 'ruby2js/filter/angularrb'

source = File.expand_path('../vendor/angular.min.js', __FILE__)

Wunderbar::Asset.script :name => 'angular-min.js', :file => source

module Wunderbar
  class HtmlMarkup
    def _ng_template(attrs={}, &block)
      if attrs.empty? and not block
        proxiable_tag! :ng_template
      else
        attrs[:type] ||= 'text/ng-template'
        tag! :script, attrs, &block
      end
    end
  end
end
