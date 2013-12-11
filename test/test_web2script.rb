require 'test/unit'
require File.expand_path('../../tools/web2script.rb', __FILE__)

class Web2ScriptTest < Test::Unit::TestCase
  def convert(string)
    nodes = Nokogiri::HTML.fragment(string).children
    $q = []
    nodes.each {|node| web2script(node)}
    $q.join("\n")
  end

  def test_simple_element
    assert_equal '_br',
      convert('<br>')
  end

  def test_hyphenated_element
    assert_equal '_ng_view',
      convert('<ng-view>')
  end

  def test_simple_attribute
    assert_equal "_div style: 'color: blue'",
      convert('<div style="color: blue">')
  end

  def test_hyphenated_attribute
    assert_equal "_div ng_controller: 'main'",
      convert('<div ng-controller="main">')
  end

  def test_namespaced_attribute
    assert_equal "_image 'xlink:href' => 'logo.png'",
      convert('<image xlink:href="logo.png">') # as found in SVG contentk
  end

  def test_boolean_attribute
    assert_equal "_input :disabled",
      convert('<input disabled>')
  end

  def test_class_attributes
    assert_equal "_div.content.first",
      convert('<div class="content first">')
  end

  def test_id_attribute
    assert_equal "_div.search!",
      convert('<div id="search">')
  end

  def test_text_content
    assert_equal "_p 'hi'",
      convert('<p>hi')
  end

  def test_nested_content
    assert_equal "_ul do\n  _li 'one'\n  _li 'two'\nend",
      convert("<ul>\n<li>one</li>\n<li>two</li>\n</ul>")
  end

  def test_nested_content_with_implicitly_closed_elements
    assert_equal "_ul do\n  _li 'one'\n  _li 'two'\nend",
      convert("<ul>\n<li>one\n<li>two\n</ul>")
  end

  def test_script
    assert_equal "_script %{\n  alert('one');\n  alert('two')\n}",
      convert("<script>\nalert('one');\nalert('two')\n</script>")
  end

  def test_pre
    assert_equal "_pre <<-EOD.gsub(/^\\s{2}/,'')\n  alert('one');\n  " +
      "alert('two')\nEOD",
      convert("<pre>\nalert('one');\nalert('two')\n</pre>")
  end

  def test_text_width
    width, $width = $width, 80
    assert_match %r{lllll ' \+\n  'mmmmm},
      convert("<p>#{('a'..'z').map {|l| l*5}.join(' ')}</p>")
  ensure
    $width = width
  end

  def test_attr_width
    width, $width = $width, 80
    assert_match %r{data_f: 'f',\n  data_g: 'g'},
      convert("<p #{('a'..'z').map {|l| "data-#{l}='#{l}'"}.join(' ').inspect}></p>")
  ensure
    $width = width
  end

  def test_items_with_single_child
    assert_equal "_ul do\n  _li 'one'\n  _li { _b 'two' }\nend",
      convert("<ul>\n<li>one\n<li><b>two</b>\n</ul>")
  end
end
