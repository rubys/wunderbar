require 'wunderbar'
require 'coderay'
require 'nokogiri'

module Wunderbar
  class HtmlMarkup
    def _coderay(*args)

      # allow arguments in any order, disambiguate based on type
      lang, string, attrs = :ruby, '', {}
      args.each do |arg|
        case arg
          when Symbol; lang = arg
          when String; string = arg
          when Hash;   attrs = arg
        end
      end

      base = _{ CodeRay.scan(CDATANode.normalize(string), lang).div }

      # remove wrapping divs
      while base.length == 1 and base.first.name == 'div'
        div = base.first.parent.children.pop
        div.children.each {|child| child.parent = base.first.parent}
        base.first.parent.children += base.first.children
        base = div.children
      end

      # add attrs provided to pre element
      if base.length == 1 and base.first.name == 'pre'
        base.first.attrs.merge! attrs
      end
    end
  end
end
