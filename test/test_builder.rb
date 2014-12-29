require 'minitest/autorun'
require 'wunderbar'

class BuilderTest < Minitest::Test
  def test_empty
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.tag!(:script) { x.indented_text! '' }
    assert_equal %{<script>\n</script>\n}, x.target!
  end

  def test_unindented_input
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.tag!(:script) { x.indented_text! "{\n  x: 1\n}" }
    assert_equal %{<script>\n  {\n    x: 1\n  }\n</script>\n}, x.target!
  end

  def test_indented_input
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.tag!(:script) { x.indented_text! "      alert('danger');" }
    assert_equal %{<script>\n  alert('danger');\n</script>\n}, x.target!
  end

  def test_indent
    x = Wunderbar::XmlMarkup.new :indent => 8
    x.tag!(:a) { x.tag!(:b) }
    assert_match %r{<a>\n {8}<b></b>\n</a>\n}, x.target!
  end

  def test_exception
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.tag!(:body) do
      begin
        x.tag!(:p) { raise Exception.new('boom') }
      rescue Exception => e
        x.tag!(:pre, e)
      end
    end
    assert x.target!.include? '<p>' and x.target!.include? '</p>'
  end

  def test_dump_string
    assert_equal "<source/>\n", Wunderbar::XmlMarkup.dump("<source>")
  end

  def test_dump_fragment
    content = Nokogiri::HTML5.fragment('<source>')
    assert_equal "<source/>\n", Wunderbar::XmlMarkup.dump(content)
  end

  def test_dump_document
    content = Nokogiri::HTML5.parse('<source>')
    assert_equal "<!DOCTYPE html>\n<html>\n  <head></head>\n  <body>\n    " +
      "<source/>\n  </body>\n</html>\n", Wunderbar::XmlMarkup.dump(content)
  end
end
