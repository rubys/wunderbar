require 'test/unit'
require 'wunderbar'

class AddonTest < Test::Unit::TestCase
  def setup
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
  end

  def target
    @x._.target!
  end

  begin
    require 'wunderbar/coffeescript'

    def test_coffeescript
      verbose, $VERBOSE = $VERBOSE, nil
      @x.html {_coffeescript 'alert "foo"'}
      assert_match %r[<script\slang="text/javascript">\s+\(function\(\)\s
        \{\s+alert\("foo"\);\s+\}\).call\(this\);\s+</script>]x, target
    ensure
      $VERBOSE = verbose
    end
  rescue LoadError => exception1
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_coffeescript) {skip exception1.inspect}
    end
  end

  begin
    require 'wunderbar/markdown'

    def test_markdown
      @x.html {_markdown "test\n=\n\nHello world!"}
      assert_match %r[<h1 id="test">test</h1>\n\n +<p>Hello world!</p>],
        target
    end
  rescue LoadError => exception2
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_markdown) {skip exception2.inspect}
    end
  end

  begin
    require 'wunderbar/coderay'

    def test_coderay
      @x.html {_coderay :ruby, "def f\n  1\nend", class: 'foo'}
      assert_match %r[<pre\sclass="foo"><span.*?>def</span>\s<span.*?>f</span>\n
        \s\s<span.*?>1</span>\n<span.*?>end</span></pre>]x, target
    end
  rescue LoadError => exception3
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_coderay) {skip exception2.inspect}
    end
  end
end
