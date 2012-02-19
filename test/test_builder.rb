require 'test/unit'
require 'rubygems'
require 'wunderbar'

class BuilderTest < Test::Unit::TestCase
  def test_empty
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.script { x.indented_text! '' }
    assert_equal %{<script>\n</script>\n}, x.target!
  end

  def test_unindented_input
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.script { x.indented_text! "{\n  x: 1\n}" }
    assert_equal %{<script>\n  {\n    x: 1\n  }\n</script>\n}, x.target!
  end

  def test_indented_input
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.script { x.indented_text! "      alert('danger');" }
    assert_equal %{<script>\n  alert('danger');\n</script>\n}, x.target!
  end

  def test_exception
    x = Wunderbar::XmlMarkup.new :indent => 2
    x.body do
      begin
        x.p { raise Exception.new('boom') }
      rescue Exception => e
        x.pre e
      end
    end
    assert x.target!.include? '<p>' and x.target!.include? '</p>'
  end
end
