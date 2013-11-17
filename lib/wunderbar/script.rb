require 'wunderbar'
require 'ruby2js'

module Wunderbar
  class HtmlMarkup
    def _script(*args, &block)
      if block
        args.unshift Ruby2JS.convert(block)
        super *args, &nil
      else
        super
      end
    end
  end
end
