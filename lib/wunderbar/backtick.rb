# Redefine backtic in HTML templates to do a Ruby => JS conversion.  Useful
# when there is a substantial amount of embedded JavaScript.

require 'ruby2js'

class Wunderbar::HtmlMarkup
  def `(input)
    Ruby2JS.convert(input)
  end
end
