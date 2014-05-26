require 'minitest/autorun'
require 'wunderbar/backtick'

class BackticTest < Minitest::Test
  def test_backtic
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
    @x.html do
      _div ng_if: `a or b`
    end
    assert_match %r{ng-if="a \|\| b"}, @x._.target!
  end
end
