require 'wunderbar'

source = Dir[File.expand_path('../vendor/polymer-*.min.js', __FILE__)].
  sort_by {|name| name[/-v?([.\d]*)\.min.js$/,1].split('.').map(&:to_i)}.last

Wunderbar::Asset.script :name => 'polymer-min.js', :file => source

if self.to_s == 'main'
  class << self
    def _polymer_element(*args, &block)
      Wunderbar.polymer_element(*args, &block)
    end
  end

  module Wunderbar
    def self.polymer_element(*args, &block)
      callback = Proc.new do |scope, args, block| 
        polymer_element(scope, *args, &block)
      end
      @queue << [callback, args, block]
    end
    
    class CGI
      def polymer_element(scope, *args, &block)
        headers = { 'type' => 'text/html', 'charset' => 'UTF-8' }
        x = HtmlMarkup.new(scope)

        begin
           element = x._polymer_element *args do
            x.instance_eval &block
          end
          output = element.serialize.join("\n") + "\n"
        rescue ::Exception => exception
          headers['status'] =  "500 Internal Server Error"
          x.clear!
          output = x.html(*args) do
            _h1 'Internal Server Error'
            _exception exception
          end
        end

        out?(scope, headers) { output }
      end
    end
  end
end

module Wunderbar
  module SinatraHelpers
    def _polymer_element(*args, &block)
      Wunderbar::Template::Html.evaluate('_polymer_element', self) do
        _polymer_element(*args) { instance_eval &block }
      end
    end
  end
end
