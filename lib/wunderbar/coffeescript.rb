require 'wunderbar'
require 'coffee-script'

module Wunderbar
  class HtmlMarkup
    def _coffeescript(text)
      _script CoffeeScript.compile(text)
    end
  end
end
