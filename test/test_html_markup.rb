require 'minitest/autorun'
require 'wunderbar'

class HtmlMarkupTest < MiniTest::Test
  def setup
    @original_log_level = Wunderbar.logger.level
    Wunderbar.log_level = :fatal
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params, :env).new({}, {}))
  end

  def target
    @x._.target!
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

  def test_html_title
    @x.html('title') {}
    assert_match %r{<title>title</title>}, target
  end

  def test_void_element
    @x.html {_br}
    assert_match %r{<br/>}, target
  end

  def test_normal_element
    @x.html {_textarea}
    assert_match %r{<textarea></textarea>}, target
  end

  def test_normal_element_with_nil
    @x.html {_textarea nil, :rows => 6}
    assert_match %r{<textarea rows="6"></textarea>}, target
  end

  def test_namespaced_element_via_tag
    @x.html {_.tag! "g:plusone"}
    assert_match %r{<g:plusone></g:plusone>}, target
  end

  def test_script_lang
    @x.html {_script}
    assert_match %r[<script lang="text/javascript">], target
  end

  def test_script_id
    @x.html {_script.id!}
    assert_match %r[<script[^>]* id="id"[^>]*>], target
  end

  def test_style_type
    @x.html {_style}
    assert_match %r[<style type="text/css">], target
  end

  def test_style_system
    @x.html {_style :system}
    assert_match %r[pre\._stderr], target
  end

  def test_script_plain
    @x.html {_script! 'alert("foo");'}
    assert_match %r[<script>alert\("foo"\);</script>], target
  end

  def test_script_indent
    @x.html {_script "if (i<1) {}"}
    assert_match %r[^ {6}if], target
  end

  def test_p_indent
    @x.html {_p "a\nb"}
    assert_match %r[^ {6}a], target
  end

  def test_script_unwrapped
    @x.html {_script "if (i>1) {}"}
    assert_match %r[<script.*>\S*\s*if \(i>1\) \{\}\s*\S*</script>], target
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
    assert_match %r[<div class="one">\s+<p>\s+<br/>\s+\u00a9\s+</p>], target
    assert_match %r[<script>foo</script>], target
    assert_match %r[<script>//<!\[CDATA\[\s+1<2\s+//\]\]></script>], target
    assert_match %r[<style>foo</style>], target
    assert_match %r[<style>/\*<!\[CDATA\[\*/\s+
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
    assert_match %r[<div class="one">\s+<p><br/>(\302\251|&#169;)</p>]u,
      target
    assert_match %r[<div class="two">\s+<script>foo</script>], target
    assert_match %r[<div\sclass="three">\s+<script>//<!\[CDATA\[\s+
      1<2\s+//\]\]></script>]x, target
    assert_match %r[<div class="four">\s+<style>foo</style>], target
    assert_match %r[<div\sclass="five">\s+<style>/\*<!\[CDATA\[\*/\s+
      a:before\s\{content:\s"<"\}\s+/\*\]\]>\*/</style>]x, target
  end

  def test_safe_markup_undefined
    markup = "<b>bold</b>"
    @x.html {_p markup}
    assert_match %r[<p>&lt;b&gt;bold&lt;/b&gt;</p>], target
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

  def test_spaced_text
    @x.html {_div {_ 'one'; __; _ 'two'}}
    assert_match %r[<div>\n +one\n\n +two\n +</div>], 
      target
  end

  def test_spaced_block
    @x.html {_div {_ 'one'; __{'<br/>'}; _ 'two'}}
    assert_match %r[<div>\n +one\n\n +<br/>\n\n +two\n +</div>], 
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
    assert_match %r[<head>\n +<style>em \{color: red\}</style>\n], target
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

  begin
    require 'nokogiri'

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
  rescue LoadError => exception
    define_method(:test_nokogiri) {skip exception.inspect}
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

  def test_rescue_cleanly
    @x.html {_div {_span; boom} rescue nil; _div}
    assert_match %r[<div>\s+<span></span>\s+</div>\s+<div></div>], target
  end

  def test_meta_charset
    @x.html {_head}
    assert_match %r[<head>\s*<meta charset="utf-8"/>\s*], target
  end

  def test_nil_attribute
    @x.html {_div :class => nil}
    assert_match %r[^ +<div></div>], target
  end

  def test_class_attribute
    @x.html {_div.header {_span.text 'foo'}}
    assert_match %r[<div class="header">\n.*\s+</div>]m, target
  end

  def test_class_compact_attribute
    @x.html {_div!.header {_span 'foo'}}
    assert_match %r[<div class="header"><span>.*</span></div>]m, target
  end

  def test_class_compact_spaced
    @x.html {_p_! {_ 'a'; _ 'b'}; _p}
    assert_match %r[<p>ab</p>\n\n +<p>]m, target
  end

  def test_class_with_dash
    @x.html {_div.header_4 {_span.text 'foo'}}
    assert_match %r[<div class="header-4">.*</div>]m, target
  end

  def test_class_attribute_merge
    @x.html {_div.header_4 class: '{{foo}}'}
    assert_match %r[<div class="header-4 {{foo}}"></div>]m, target
  end

  def test_id_attribute
    @x.html {_h1.content! 'Content'}
    assert_match %r[^ +<h1 id="content">Content</h1>], target
    refute_match %r[<h1>], target
  end

  def test_compact_id_attribute
    @x.html {_h3!.content! {_em 'Content'}}
    assert_match %r[^ +<h3 id="content"><em>Content</em></h3>], target
    refute_match %r[<h1>], target
  end

  def test_multiple_proxy
    @x.html {_h1.a.b.content! 'Content'}
    assert_match %r[^ +<h1 class="a b" id="content">Content</h1>], target
    refute_match %r[><\/h1>], target
  end

  def test_underbar_proxy
    @x.html {_my_node.a.b! 'Content'}
    assert_match %r[^ +<my-node class="a" id="b">Content</my-node>], target
    refute_match %r[><\/h1>], target
  end

  def test_multiple_proxy_spaced
    @x.html {_h1; _h1_.a.b.content! 'Content'}
    assert_match %r[</h1>\n\n +<h1 class="a b" id="content">], target
  end

  def test_proxy_spaced_compact
    @x.html {_div_!.o { _b 'a'; _em 'b' }; _div}
    assert_match %r[<div class="o"><b>a</b><em>b</em></div>\n\n +<div>],
      target
  end

  def test_svg_class_attribute
    @x.html {_svg.pie {_circle :r => 10}}
    assert_match %r[<svg.*? class="pie".*>]m, target
    assert_match %r[<svg.*? xmlns="http://www.w3.org/2000/svg".*?>], target
  end

  def test_boolean_attribute_false
    @x.html {_option :selected => false}
    assert_match %r[^ +<option></option>], target
  end

  def test_boolean_attribute_true
    @x.html {_option :selected => true}
    assert_match %r[^ +<option selected="selected"></option>], target
  end

  def test_boolean_attribute_symbol
    @x.html {_option :selected}
    assert_match %r[^ +<option selected="selected"></option>], target
  end

  def test_class_boolean_attribute_false
    @x.html {_option.name :selected => false}
    assert_match %r[^ +<option class="name"></option>], target
  end

  def test_class_boolean_attribute_true
    @x.html {_option.name :selected => true}
    assert_match %r[selected="selected"], target
  end

  def test_indented_text
    @x.html {_div {_ 'text'}}
    assert_match %r[^ {4}+<div>\n {6}text\n {4}</div>], target
  end

  def test_unindented_text
    @x.html {_div {_! "text\n"}}
    assert_match %r[^ +<div>\ntext\n +</div>], target
  end

  def test_unindented_pre
    @x.html {_div {_pre {_{"before\n<b><i>middle</i></b>\nafter"}}}}
    assert_match %r[^ +<pre>before\n<b><i>middle</i></b>\nafter</pre>], target
  end

  def test_pre_newline
    @x.html {_div _{"<pre>before\n<b><i>middle</i></b>\nafter</pre>"}}
    assert_match %r[^ +<pre>before\n<b><i>middle</i></b>\nafter</pre>], target
  end

  def test_literal_markup
    @x.html {_{"<p>one</p>\n\n<p>two</p>\n"}}
    assert_match %r[^( +)<p>one</p>\n\n\1<p>two</p>], target
  end

  def test_markup
    @x.html { _ '<3' } # as per README
    assert_match %r{^( +)&lt;3}, target
  end

  def test_proc
    content = proc do
      _p 'one'
      __
      _p 'two'
    end

    @x.html {_(&content)}
    assert_match %r[^( +)<p>one</p>\n\n\1<p>two</p>], target
  end

  def test_chomped_pre
    @x.html {_div {_pre "before\nmiddle\nafter\n"}}
    assert_match %r[^ +<pre>before\nmiddle\nafter</pre>], target
  end

  def test_chomped_pre_class
    @x.html {_div {_pre.x "before\nmiddle\nafter\n"}}
    assert_match %r[^ +<pre class="x">before\nmiddle\nafter</pre>], target
  end

  def test_unchomped_textarea_class
    @x.html {_div {_textarea.x "before\nmiddle\nafter\n"}}
    assert_match %r[^ +<textarea class="x">before\nmiddle\nafter\n</textarea>], target
  end

  def test_textarea_unflowed
    text = (%w(word)*40).join(' ')
    @x.html(_width:40) {_div {_textarea.x text}}
    assert_match %r[^ +<textarea class="x">.*</textarea>], target
  end

  def test_pre_unflowed
    text = (%w(word)*40).join(' ')
    @x.html(_width:40) {_div {_pre.x text}}
    assert_match %r[^ +<pre class="x">.*</pre>], target
  end

  def test_imported_textarea
    @x.html {_ {"<textarea>before\nmiddle\nafter</textarea>"}}
    assert_match %r[^ +<textarea>before\nmiddle\nafter</textarea>], target
  end

  def test_declare
    @x._.declare! :DOCTYPE, 'html'
    assert_equal %{<!DOCTYPE html>\n}, target
  end

  def test_comment
    @x._.comment! 'foo'
    assert_equal %{<!-- foo -->\n}, target
  end

  def test_system
    @x.html {_.system ['echo', 'hi']}
    assert_match %r[<pre class=\"_stdin\">echo hi</pre>], target
    assert_match %r[<pre class=\"_stdout\">hi</pre>], target
  end

  def test_system_multiline_pre_default
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..']} # generate two lines of output
    assert_equal rc, 0
    assert_match %r[<pre class="_stdin">ls -d1 . ..</pre>], target
    assert_match %r[<pre class="_stdout">.\n..</pre>], target
  end

  def test_system_multiline_pre_true
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..'], {bundlelines: true}} # generate two lines of output
    assert_equal rc, 0
    assert_match %r[<pre class="_stdin">ls -d1 . ..</pre>], target
    assert_match %r[<pre class="_stdout">.\n..</pre>], target
  end

  def test_system_multiline_pre_false
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..'], {bundlelines: false}}
    assert_equal rc, 0
    assert_match %r[<pre class="_stdin">ls -d1 . ..</pre>], target
    assert_match %r[<pre class="_stdout">.</pre>], target
    assert_match %r[<pre class="_stdout">..</pre>], target
  end

  def test_system_multiline_code_default
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..'], {tag: 'code'}}
    assert_equal rc, 0
    assert_match %r[<code class="_stdin">ls -d1 . ..</code>], target
    assert_match %r[<code class="_stdout">.</code>], target
    assert_match %r[<code class="_stdout">..</code>], target
  end

  def test_system_multiline_code_false
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..'], {tag: 'code', bundlelines: false}}
    assert_equal rc, 0
    assert_match %r[<code class="_stdin">ls -d1 . ..</code>], target
    assert_match %r[<code class="_stdout">.</code>], target
    assert_match %r[<code class="_stdout">..</code>], target
  end

  def test_system_multiline_code_true
    rc = nil
    @x.html {rc = _.system ['ls', '-d1', '.', '..'], {tag: 'code', bundlelines: true}}
    assert_equal rc, 0
    assert_match %r[<code class="_stdin">ls -d1 . ..</code>], target
    assert_match %r[<code class="_stdout">.\n..</code>], target
  end

  def test_system_opts
    Dir.mktmpdir do |dir|
      @x.html {_.system ['pwd'], { system_opts: { chdir: dir} }}
      assert_includes target, dir
    end
  end

  def test_system_env
    @x.html {_.system ['printenv', 'XXTEST'], { system_env: { 'XXTEST' => 'The quick brown fox' } }}
    assert_match %r[<pre class=\"_stdout\">The quick brown fox</pre>], target
  end

  def test_svg
    @x.html {_svg}
    assert_match %r[^ +<svg xmlns="http://www.w3.org/2000/svg"/?>], target
  end

  def test_math
    @x.html {_math}
    assert_match %r[^ +<math xmlns="http://www.w3.org/1998/Math/MathML"/?>],
      target
  end

  def test_width_element_text
    @x.html :_width => 80 do
      _p ('a'..'z').map {|l| l*5}.join(' ')
    end
    assert_match(/lllll\n {6}mmmmm/, target)
  end

  def test_width_nl
    @x.html :_width => 80 do
      _p {_b "a\nb"}
    end
    assert_match(/<b>\s*a b\s*<\/b>/, target)
  end

  def test_width_indented_text
    @x.html :_width => 80 do
      _ ('a'..'z').map {|l| l*5}.join(' ')
    end
    assert_match(/lllll\n {4}mmmmm/, target)
  end

  def test_width_cdata
    data = ('a'..'z').map {|l| l*5}.join(' ')
    @x.html :_width => 80 do
      _script %{
        #{data}
      }
    end
    assert_match(/#{data}/, target)
  end

  def test_width_pre
    data = ('a'..'z').map {|l| l*5}.join(' ')
    @x.html :_width => 80 do
      _pre %{
        #{data}
      }
    end
    assert_match(/#{data}/, target)
  end

  def test_width_compact_elements
    @x.html :_width => 80 do
      _div! do
        5.times {|i| _a i, :href=>i; _ ', '}
      end
    end
    assert_match(/<a href="1">1<\/a>, <a href="2">2<\/a>,\n {6}<a href="3">/, 
      target)
  end

  def test_width_compact_text
    words = %w(one two three four five six seven eight nine ten eleven twelve
      thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty)

    @x.html :_width => 80 do
      _div! do
        _span { _span words.join(' ') }
      end
    end
    assert_match(/<div><span><span>one/, target)
    assert_match(/eleven\n +twelve thirteen/, target)
    assert_match(%r{\n {6}twenty</span></span></div>}, target)
  end

  def test_implicit_elements
    @x.html do
      _h1 'title'
    end
    assert_match(/^  <head>/, target)
    assert_match(/^    <title>title<\/title>/, target)
    assert_match(/^  <\/head>\n\n/, target)
    assert_match(/^  <body>/, target)
    assert_match(/^    <h1>title<\/h1>/, target)
  end

  def test_head_reordering_title
    @x.html do
      _script 'alert("Yo!")'
      _h1 'title'
    end
    assert_match(/<meta.*>\s*<title>title<\/title>\s*<script/, target)
  end

  def test_null_base
    @x.html do
      _script 'alert("Yo!")'
      _base
    end
    assert_match %r{<meta.*>\s*<base/>\s*<script}, target
  end

  def test_head_reordering_base
    @x.html do
      _script 'alert("Yo!")'
      _base href: '/'
    end
    assert_match %r{<meta.*>\s*<base href="/"/>\s*<script}, target
  end

  def test_frameset
    @x.html do
      _frameset cols: '20%, 60%' do
        _frame name: 'viewport1'
        _frame name: 'viewport2'
      end
    end

    assert_match %r{</head>\s*<frameset}, target
    assert_match %r{</frameset>\s*</html}, target.
      gsub(%r{<script.*?></script>\s*}, '')
  end

  def test_underscore_to_dash
    @x.html do
      _span :data_foo => 'bar'
      _x_element
      _div 'data_foo' => 'bar'
      _.tag! 'under_bar'
    end
    assert_match(/<span data-foo="bar">/, target)
    assert_match(/<x-element>/, target)
    assert_match(/<div data_foo="bar">/, target)
    assert_match(/<under_bar>/, target)
  end

  def test_template
    Wunderbar.templates['website-layout'] = Proc.new do
      _h1 @title
      _div.content do
        _yield
      end
    end

    @x.html do
      _website_layout title: 'template test' do
        _p 'It worked!'
      end
    end
    assert_match %r{<title>template test</title>}, target
    assert_match %r{<div class="content">\s+<p>It worked!</p>}, target
  ensure
    Wunderbar.templates.clear
  end

  def test_ul_array
    @x.html do
      _ul %w(apple orange pear)
    end
    assert_match %r{<ul>\s+<li>apple</li>}, target
  end

  def test_ul_array_each
    @x.html do
      _ul %w(apple orange pear) do |fruit|
        _li fruit.capitalize
      end
    end
    assert_match %r{<ul>\s+<li>Apple</li>}, target
  end

  def test_ol_class_array
    @x.html do
      _ol.fruit %w(apple orange pear)
    end
    assert_match %r{<ol class="fruit">}, target
    assert_match %r{<li>orange</li>}, target
  end

  def test_dl_each
    @x.html do
      _dl red: '#F00', green: '#0F0', blue: '#00F' do |color, hex|
        _dt color.to_s
        _dd hex
      end
    end
    assert_match %r{<dl>}, target
    assert_match %r{<dt>green</dt>\s*<dd>#0F0</dd>\s*<dt>blue</dt>}, target
  end

  def test_dl_each_class
    @x.html do
      _dl.colors red: '#F00', green: '#0F0', blue: '#00F' do |color, hex|
        _dt color.to_s
        _dd hex
      end
    end
    assert_match %r{<dl class="colors">}, target
    assert_match %r{<dt>green</dt>\s*<dd>#0F0</dd>\s*<dt>blue</dt>}, target
  end

  def test_dl_each_id
    @x.html do
      _dl.colors! red: '#F00', green: '#0F0', blue: '#00F' do |color, hex|
        _dt color.to_s
        _dd hex
      end
    end
    assert_match %r{<dl id="colors">}, target
    assert_match %r{<dt>green</dt>\s*<dd>#0F0</dd>\s*<dt>blue</dt>}, target
  end

  def test_form_id
    @x.html do
      _form.comment! method: 'post' do
      end
    end
    assert_match %r{<form id="comment" method="post">}, target
  end

  def test_tr
    @x.html do
      _table do
        _tr %w(apple orange pear)
      end
    end
    assert_match %r{<tr>\s+<td>apple</td>}, target
  end

  def test_nbsp
    @x.html do
      _p "A\u00A0B"
    end
    assert_match %r{<p>A&#xA0;B</p>}, target
  end

  def test_issue_16
    h3 = 'email "Some One" <someone@gmail.com>'
    @x.html do
      _h3 h3
    end
    assert_match %r{<h3>email "Some One" &lt;someone@gmail.com&gt;</h3>}, target
  end
end
