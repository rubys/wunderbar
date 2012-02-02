require 'test/unit'
require 'rubygems'
require 'cgi-spa'

class HtmlMarkupTest < Test::Unit::TestCase
  def setup
    $x = nil # until this hack is removed html-methods.rb
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
    x.declare! :DOCTYPE, 'html'
    assert_equal %{<!DOCTYPE "html">\n}, x.target!
  end
end
