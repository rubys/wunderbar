require 'test/unit'
require 'rubygems'
require 'wunderbar'

class Extension < Wunderbar::Extension
  proc :instance do
    _instance @foo
  end

  proc :attribute do
    _attribute _.foo
  end

  proc :toplevel do
    _toplevel main_variable
  end
end

class HtmlExtensionTest < Test::Unit::TestCase
  def setup
    @x = Wunderbar::HtmlMarkup.new(Struct.new(:params).new({}))
  end

  def target
    @x._.target!.join
  end

  def test_instance
    @x.html do
      @foo = 'bar'
      _ Extension.instance
    end

    assert_match %r{<instance>bar</instance>}, target
  end

  def test_attribute
    @x.html do
      _.attr_accessor :foo
      _.foo = 'baz'
      _ Extension.attribute
    end

    assert_match %r{<attribute>baz</attribute>}, target
  end

  def test_toplevel
    TOPLEVEL_BINDING.eval "main_variable = 'plugh'"

    @x.html do
      _ Extension.toplevel
    end

    assert_match %r{<toplevel>plugh</toplevel>}, target
  end
end

class JsonExtensionTest < Test::Unit::TestCase
  def setup
    @j = Wunderbar::JsonBuilder.new(Struct.new(:params).new({}))
  end

  def test_instance
    @j.encode do
      @foo = 'bar'
      _ Extension.instance
    end

    assert_match %{{"instance":"bar"}}, @j.target!.gsub(/\s/,'')
  end

  def test_attribute
    @j.encode do
      _.attr_accessor :foo
      _.foo = 'baz'
      _ Extension.attribute
    end

    assert_match %{{"attribute":"baz"}}, @j.target!.gsub(/\s/,'')
  end

  def test_toplevel
    TOPLEVEL_BINDING.eval "main_variable = 'xyzzy'"

    @j.encode do
      _ Extension.toplevel
    end

    assert_match %{{"toplevel":"xyzzy"}}, @j.target!.gsub(/\s/,'')
  end
end
