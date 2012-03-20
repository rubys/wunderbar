require 'test/unit'
require 'rubygems'
require 'wunderbar'

class HtmlMarkupTest < Test::Unit::TestCase
  def setup
    @original_log_level = Wunderbar.logger.level
    Wunderbar.log_level = :fatal
  end

  def teardown
    Wunderbar.logger.level = @original_log_level
  end

  def test_html
    x = HtmlMarkup.new
    x.html {}
    assert_equal %{<html>\n</html>\n}, x.target!
  end

  def test_void_element
    x = HtmlMarkup.new
    x.html {_br}
    assert_match %r{<br/>}, x.target!
  end

  def test_normal_element
    x = HtmlMarkup.new
    x.html {_textarea}
    assert_match %r{<textarea></textarea>}, x.target!
  end

  def test_script_lang
    x = HtmlMarkup.new
    x.html {_script}
    assert_match %r[<script lang="text/javascript">], x.target!
  end

  def test_style_type
    x = HtmlMarkup.new
    x.html {_style}
    assert_match %r[<style type="text/css">], x.target!
  end

  def test_script_plain
    x = HtmlMarkup.new
    x.html {_script! 'alert("foo");'}
    assert_match %r[<script>alert\("foo"\);</script>], x.target!
  end

  def test_script_indent
    x = HtmlMarkup.new
    x.html {_script "if (i<1) {}"}
    assert_match %r[^    if], x.target!
  end

  def test_script_html
    $XHTML = false
    x = HtmlMarkup.new
    x.html {_script "if (i<1) {}"}
    assert_match %r[<script.*>\s*if \(i<1\) \{\}\s*</script>], x.target!
  end

  def test_script_xhtml
    $XHTML = true
    x = HtmlMarkup.new
    x.html {_script "if (i<1) {}"}
    assert_match %r[<script.*>\s*if \(i&lt;1\) \{\}\s*</script>], x.target!
  end

  def test_disable_indent
    x = HtmlMarkup.new
    x.html {_div! {_ "one "; _strong "two"; _ " three"}}
    assert_match %r[<div>one <strong>two</strong> three</div>], x.target!
  end

  def test_spaced_embedded
    x = HtmlMarkup.new
    x.html {_div {_p 'one'; _hr_; _p 'two'}}
    assert_match %r[<div>\n +<p>one</p>\n\n +<hr/>\n\n +<p>two</p>\n +</div>], 
      x.target!
  end

  def test_spaced_collapsed
    x = HtmlMarkup.new
    x.html {_div {_p_ 'one'; _hr_; _p_ 'two'}}
    assert_match %r[<div>\n +<p>one</p>\n\n +<hr/>\n\n +<p>two</p>\n +</div>], 
      x.target!
  end

  def test_traceback
    x = HtmlMarkup.new
    x.html {_body? {boom}}
    assert_match %r[<pre.*>#&lt;NameError: .*boom], 
      x.target!
  end

  def test_traceback_default_style
    x = HtmlMarkup.new
    x.html {_body? {boom}}
    assert_match %r[<pre style="background-color:#ff0.*">], x.target!
  end

  def test_traceback_style_override
    x = HtmlMarkup.new
    x.html {_body?(:traceback_style => 'color:red') {boom}}
    assert_match %r[<pre style="color:red"], x.target!
  end

  def test_traceback_class_override
    x = HtmlMarkup.new
    x.html {_body?(:traceback_class => 'traceback') {boom}}
    assert_match %r[<pre class="traceback"], x.target!
  end

  def test_meta_charset
    x = HtmlMarkup.new
    x.html {_head}
    assert_match %r[<head>\s*<meta charset="utf-8"/>\s*</head>], x.target!
  end

  def test_nil_attribute
    x = HtmlMarkup.new
    x.html {_div :class => nil}
    assert_match %r[^  <div></div>], x.target!
  end

  def test_boolean_attribute_false
    x = HtmlMarkup.new
    x.html {_option :selected => false}
    assert_match %r[^  <option></option>], x.target!
  end

  def test_boolean_attribute_true
    x = HtmlMarkup.new
    x.html {_option :selected => true}
    assert_match %r[^  <option selected="selected"></option>], x.target!
  end

  def test_indented_text
    x = HtmlMarkup.new
    x.html {_div {_ 'text'}}
    assert_match %r[^  <div>\n    text\n  </div>], x.target!
  end

  def test_unindented_text
    x = HtmlMarkup.new
    x.html {_div {_! "text\n"}}
    assert_match %r[^  <div>\ntext\n  </div>], x.target!
  end

  def test_declare
    x = HtmlMarkup.new
    x._.declare :DOCTYPE, 'html'
    assert_equal %{<!DOCTYPE "html">\n}, x.target!
  end

  def test_comment
    x = HtmlMarkup.new
    x._.comment 'foo'
    assert_equal %{<!-- foo -->\n}, x.target!
  end

  def test_svg
    x = HtmlMarkup.new
    x.html {_svg}
    assert_match %r[^  <svg xmlns="http://www.w3.org/2000/svg"/>], x.target!
  end

  def test_math
    x = HtmlMarkup.new
    x.html {_math}
    assert_match %r[^  <math xmlns="http://www.w3.org/1998/Math/MathML"/>], x.target!
  end

  begin
    require 'coffee-script'

    def test_coffeescript
      x = HtmlMarkup.new
      x.html {_coffeescript 'alert "foo"'}
      assert_match %r[<script\slang="text/javascript">\s+\(function\(\)\s
        \{\s+alert\("foo"\);\s+\}\).call\(this\);\s+</script>]x, x.target!
    end
  rescue LoadError
  end
    
end
