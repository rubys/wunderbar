require 'wunderbar'
require 'opal'
require 'sourcify'

Wunderbar::Asset.script :name => 'opal.js',
  :contents => Opal::Builder.build('opal')

module Wunderbar
  class HtmlMarkup
    def _script(*args, &block)
      if block
        args.unshift Opal.parse(block.to_source(:strip_enclosure => true))
        super *args, &nil
      else
        super
      end
    end
  end
end
