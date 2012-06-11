require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'nokogiri'

class HtmlMarkupTest < Test::Unit::TestCase
  def setup
    @original_log_level = Wunderbar.logger.level
    Wunderbar.log_level = :fatal
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
  end

  def target
    @x._.target!.join
  end

  def teardown
    Wunderbar.logger.level = @original_log_level
  end

  def test_html
    @x.html {}
    assert_match %r{<!DOCTYPE html>}, target
    assert_match %r{<html xmlns="http://www.w3.org/1999/xhtml">}, target
    assert_match %r{</html>}, target
  end

  def test_void_element
    @x.html {_br}
    assert_match %r{<br/>}, target
  end

  def test_normal_element
    @x.html {_textarea}
    assert_match %r{<textarea></textarea>}, target
  end

  def test_namespaced_element
    @x.html {_g :plusone}
    assert_match %r{<g:plusone></g:plusone>}, target
  end

  def test_script_lang
    @x.html {_script}
    assert_match %r[<script lang="text/javascript">], target
  end

  def test_style_type
    @x.html {_style}
    assert_match %r[<style type="text/css">], target
  end

  def test_script_plain
    @x.html {_script! 'alert("foo");'}
    assert_match %r[<script>alert\("foo"\);</script>], target
  end

  def test_script_indent
    @x.html {_script "if (i<1) {}"}
    assert_match %r[^    if], target
  end

  def test_p_indent
    @x.html {_p "a\nb"}
    assert_match %r[^    a], target
  end

  def test_script_unwrapped
    @x.html {_script "if (i>1) {}"}
    assert_match %r[<script.*>\s*if \(i>1\) \{\}\s*</script>], target
  end

  def test_script_wrapped
    @x.html {_script "if (i<1) {}"}
    assert_match %r[<script.*>//<!\[CDATA\[\s*
      if\s\(i<1\)\s\{\}\s*//\]\]></script>]x, target
  end

  def test_non_xhtml_markup_import
    @x.html do
      _div.one   {_ {'<p><br>&copy;'}}
      _div.two   {_ {'<script>foo</script>'}}
      _div.three {_ {'<script>1<2</script>'}}
      _div.four  {_ {'<style>foo</style>'}}
      _div.five  {_ {'<style>a:before {content: "<"}</style>'}}
    end
    if RUBY_VERSION =~ /^1\.8/
      assert_match %r[<div class="one">\s+<p>\s+<br/>\s+\302\251\s+</p>],
        target
    else
      assert_match %r[<div class="one">\s+<p>\s+<br/>\s+\u00a9\s+</p>], target
    end
    assert_match %r[<div class="two">\s+<script>\s+foo\s+</script>], target
    assert_match %r[<div\sclass="three">\s+<script>//<!\[CDATA\[\s+
      1<2\s+//\]\]></script>]x, target
    assert_match %r[<div class="four">\s+<style>\s+foo\s+</style>], target
    assert_match %r[<div\sclass="five">\s+<style>/\*<!\[CDATA\[\*/\s+
      a:before\s\{content:\s"<"\}\s+/\*\]\]>\*/</style>]x, target
  end

  def test_non_xhtml_markup_shift
    @x.html do
      _div.one   {_ << '<p><br>&copy;'}
      _div.two   {_ << '<script>foo</script>'}
      _div.three {_ << '<script>1<2</script>'}
      _div.four  {_ << '<style>foo</style>'}
      _div.five  {_ << '<style>a:before {content: "<"}</style>'}
    end
    if RUBY_VERSION =~ /^1\.8/
      assert_match %r[<div class="one">\s+<p><br/>\302\251</p>], target
    else
      assert_match %r[<div class="one">\s+<p><br/>&#169;</p>], target
    end
    assert_match %r[<div class="two">\s+<script>foo</script>], target
    assert_match %r[<div\sclass="three">\s+<script>//<!\[CDATA\[\s+
      1<2\s+//\]\]></script>]x, target
    assert_match %r[<div class="four">\s+<style>foo</style>], target
    assert_match %r[<div\sclass="five">\s+<style>/\*<!\[CDATA\[\*/\s+
      a:before\s\{content:\s"<"\}\s+/\*\]\]>\*/</style>]x, target
  end

  def test_safe_markup
    markup = "<b>bold</b>"
    def markup.html_safe?
      true
    end
    @x.html {_p markup}
    assert_match %r[<p>\n    <b>bold</b>\n  </p>], target
  end

  def test_disable_indent
    @x.html {_div! {_ "one "; _strong "two"; _ " three"}}
    assert_match %r[<div>one <strong>two</strong> three</div>], target
  end

  def test_spaced_embedded
    @x.html {_div {_p 'one'; _hr_; _p 'two'}}
    assert_match %r[<div>\n +<p>one</p>\n\n +<hr/>\n\n +<p>two</p>\n +</div>], 
      target
  end

  def test_spaced_collapsed
    @x.html {_div {_p_ 'one'; _hr_; _p_ 'two'}}
    assert_match %r[<div>\n +<p>one</p>\n\n +<hr/>\n\n +<p>two</p>\n +</div>], 
      target
  end

  def test_import_indented
    @x.html {_div {_ {"<p>one</p><hr><p>two</p>"}}}
    assert_match %r[<div>\n +<p>one</p>\n +<hr/>\n +<p>two</p>\n +</div>], 
      target
  end

  def test_import_collapsed
    @x.html {_div {_ {"<p>one, <em>two</em>, three</p>"}}}
    assert_match %r[<div>\n +<p>one, <em>two</em>, three</p>\n +</div>], 
      target
  end

  def test_import_style
    @x.html {_div {_ {"<style>em {color: red}</style>"}}}
    assert_match %r[<div>\n +<style>\n +em \{color: red\}\n +</style>\n], 
      target
  end

  def test_import_comment
    @x.html {_div {_ {"<br><!-- comment --><br>"}}}
    assert_match %r[<div>\n +<br/>\n +<!-- comment -->\n +<br/>\n +</div>], 
      target
  end

  def test_import_nonvoid
    @x.html {_div {_ {"<textarea/>"}}}
    assert_match %r[<textarea></textarea>], target
  end

  def test_import_tainted
    @x.html {_div {_ {"<br>".taint}}}
    assert_match %r[&lt;br&gt;], target
  end

  def test_node_simple
    @x.html {_div {_[Nokogiri::XML('<br/>')]}}
    assert_match %r[<br/>], target
  end

  def test_node_xmlns
    @x.html do
      _div {_[Nokogiri::XML('<svg xmlns="http://www.w3.org/2000/svg">')]}
    end
    assert_match %r[<svg xmlns="http://www.w3.org/2000/svg">], target
  end

  def test_node_element_prefix
    @x.html do
      _div do
        _[Nokogiri::XML('<rdf:RDF xmlns:rdf="http://www.w3.org/1999/rdf#"/>')]
      end
    end
    assert_match %r[<rdf:RDF xmlns:rdf="http://www.w3.org/1999/rdf#">], target
  end

  def test_node_attr_prefix
    @x.html do
      _div do
        _[Nokogiri::XML('<use xlink:href="#path" 
          xmlns:xlink="http://www.w3.org/1999/xlink"/>')]
      end
    end
    assert_match %r[<use.* xlink:href="#path"], target
    assert_match %r[<use.* xmlns:xlink="http://www.w3.org/1999/xlink"], target
  end

  def test_traceback
    @x.html {_body? {boom}}
    assert_match %r[<pre.*>#&lt;NameError: .*boom], 
      target
  end

  def test_traceback_default_style
    @x.html {_body? {boom}}
    assert_match %r[<pre style="background-color:#ff0.*">], target
  end

  def test_traceback_style_override
    @x.html {_body?(:traceback_style => 'color:red') {boom}}
    assert_match %r[<pre style="color:red"], target
  end

  def test_traceback_class_override
    @x.html {_body?(:traceback_class => 'traceback') {boom}}
    assert_match %r[<pre class="traceback"], target
  end

  def test_meta_charset
    @x.html {_head}
    assert_match %r[<head>\s*<meta charset="utf-8"/>\s*</head>], target
  end

  def test_nil_attribute
    @x.html {_div :class => nil}
    assert_match %r[^  <div></div>], target
  end

  def test_class_attribute
    @x.html {_div.header {_span.text 'foo'}}
    assert_match %r[<div class="header">.*</div>]m, target
  end

  def test_id_attribute
    @x.html {_h1.content! 'Content'}
    assert_match %r[^  <h1 id="content">Content</h1>], target
  end

  def test_svg_class_attribute
    @x.html {_svg.pie {_circle :r => 10}}
    assert_match %r[<svg.*? class="pie".*>]m, target
    assert_match %r[<svg.*? xmlns="http://www.w3.org/2000/svg".*?>], target
  end

  def test_boolean_attribute_false
    @x.html {_option :selected => false}
    assert_match %r[^  <option></option>], target
  end

  def test_boolean_attribute_true
    @x.html {_option :selected => true}
    assert_match %r[^  <option selected="selected"></option>], target
  end

  def test_class_boolean_attribute_false
    @x.html {_option.name :selected => false}
    assert_match %r[^  <option class="name"></option>], target
  end

  def test_class_boolean_attribute_true
    @x.html {_option.name :selected => true}
    assert_match %r[selected="selected"], target
  end

  def test_indented_text
    @x.html {_div {_ 'text'}}
    assert_match %r[^  <div>\n    text\n  </div>], target
  end

  def test_unindented_text
    @x.html {_div {_! "text\n"}}
    assert_match %r[^  <div>\ntext\n  </div>], target
  end

  def test_unindented_pre
    @x.html {_div {_pre {_{"before\n<b><i>middle</i></b>\nafter"}}}}
    assert_match %r[^    <pre>before\n<b><i>middle</i></b>\nafter</pre>], target
  end

  def test_chomped_pre
    @x.html {_div {_pre "before\nmiddle\nafter\n"}}
    assert_match %r[^    <pre>before\nmiddle\nafter</pre>], target
  end

  def test_chomped_pre
    @x.html {_div {_pre.x "before\nmiddle\nafter\n"}}
    assert_match %r[^    <pre class="x">before\nmiddle\nafter</pre>], target
  end

  def test_declare
    @x._.declare :DOCTYPE, 'html'
    assert_equal %{<!DOCTYPE "html">\n}, target
  end

  def test_comment
    @x._.comment 'foo'
    assert_equal %{<!-- foo -->\n}, target
  end

  def test_svg
    @x.html {_svg}
    assert_match %r[^  <svg xmlns="http://www.w3.org/2000/svg"/>], target
  end

  def test_math
    @x.html {_math}
    assert_match %r[^  <math xmlns="http://www.w3.org/1998/Math/MathML"/>],
      target
  end

  begin
    require 'coffee-script'

    def test_coffeescript
      verbose, $VERBOSE = $VERBOSE, nil
      @x.html {_coffeescript 'alert "foo"'}
      assert_match %r[<script\slang="text/javascript">\s+\(function\(\)\s
        \{\s+alert\("foo"\);\s+\}\).call\(this\);\s+</script>]x, target
    ensure
      $VERBOSE = verbose
    end
  rescue LoadError => exception
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_coffeescript) {skip exception.inspect}
    end
  end

  def test_width
    @x.html :_width => 80 do
      _div! do
        5.times {|i| _a i, :href=>i; _ ', '}
      end
    end
    assert_match /<a href="2">2<\/a>, <a href="3">3<\/a>,\n  <a href="4">/, 
      target
  end
end
