require 'minitest/autorun'
require 'wunderbar'

class NodeTest < Minitest::Test
  def test_css_selector
    css = %q{#sidebar .abc div.a.b *[a=value][b='foo'][c="bar"]}
    csspath = Wunderbar::Node.parse_css_selector(css)
    assert_equal 4, csspath.length
    assert_equal csspath[0], {id: "sidebar"}
    assert_equal csspath[1], {class: ["abc"]}
    assert_equal csspath[2], {name: "div", class: ["a", "b"]}
    assert_equal csspath[3], {attr: {"a"=>"value", "b"=>"foo", "c"=>"bar"}}
  end

  def test_root
    @nodes = {}
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params, :env).
      new({:nodes => @nodes}, {}))
    @x.html do
      @nodes[:div] = _div.node?
    end

    root = @nodes[:div].root 
    assert_nil root.name
    assert_equal 2, root.children.length
    assert_equal :DOCTYPE, root.children.first.declare
    assert_equal :html, root.children.last.name
  end

  def test_search
    @nodes = {}
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params, :env).
      new({:nodes => @nodes}, {}))
    @x.html do
      @nodes[:div] = _div do
        _span.top! 'A'
        _span.middle 'B'
        _span 'C', title: 'bottom' do
          _span.bottom 'D'
        end
      end
    end

    div = @nodes[:div]
    assert_equal 4, div.search('span').length
    assert_equal 'A', div.at('#top').text
    assert_equal 'B', div.at('.middle').text
    assert_equal 'C', div.at('*[title=bottom]').text
    assert_equal 'D', div.at('*[title=bottom] .bottom').text
  end
end
