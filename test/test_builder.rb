require 'test/unit'
require 'rubygems'
require 'wunderbar'

class BuilderTest < Test::Unit::TestCase
  def test_empty
    x = Builder::XmlMarkup.new :indent => 2
    x.script { x.indented_text! '' }
    assert_equal %{<script>\n</script>\n}, x.target!
  end

  def test_unindented_input
    x = Builder::XmlMarkup.new :indent => 2
    x.script { x.indented_text! "{\n  x: 1\n}" }
    assert_equal %{<script>\n  {\n    x: 1\n  }\n</script>\n}, x.target!
  end

  def test_indented_input
    x = Builder::XmlMarkup.new :indent => 2
    x.script { x.indented_text! "      alert('danger');" }
    assert_equal %{<script>\n  alert('danger');\n</script>\n}, x.target!
  end
end
