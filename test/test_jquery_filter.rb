require 'minitest/autorun'
require 'wunderbar'
require 'wunderbar/jquery/filter'

class JqueryFilterTest < MiniTest::Test
  def teardown
    Wunderbar::Asset.clear
  end

  def to_js(string)
    Ruby2JS.convert(string, filters: 
      [Ruby2JS::Filter::JQuery, Wunderbar::Filter::JQuery])
  end

  def test_name_text_attr
    assert_equal '$("<a></a>").text("text").attr({href: "link"})', 
      to_js('_a "text", href: "link"')
  end

  def test_void
    assert_equal '$("<br/>")', to_js('_br')
  end

  def test_class_id
    assert_equal '$("<p></p>").addClass("class").attr({id: "id"}).text("text")', 
      to_js('_p.class.id! "text"')
  end

  def test_id_attr
    assert_equal '$("<span></span>").attr({id: "id", title: "title"})',
      to_js('_span.id! title: "title"')
  end

  def test_id_attr
    assert_equal '$("<ul></ul>").attr({id: "id"}).' +
      'each(function(_index, _parent) ' +
      '{$("<li></li>").text("item").appendTo($(_parent))})',
      to_js('_ul.id! {_li "item"}')
  end
end
