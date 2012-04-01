require 'test/unit'
require 'rubygems'
require 'wunderbar'

class JsonTest < Test::Unit::TestCase
  def setup
    @j = Wunderbar::JsonBuilder.new
  end

  def test_hash_value
    @j.encode do
      _foo 'bar'
    end

    assert_match %{{"foo":"bar"}}, @j.target!.gsub(/\s/,'')
  end

  def test_hash_property
    @j.encode do
      _foo 'bar', :length
    end

    assert_match %{{"foo":{"length":3}}}, @j.target!.gsub(/\s/,'')
  end

  def test_nested_hash
    @j.encode do
      _foo do
        _length 'bar'.length
      end
    end

    assert_match %{{"foo":{"length":3}}}, @j.target!.gsub(/\s/,'')
  end

  def test_hash_properties
    @j.encode do
      _foo 'Bar', :upcase, :downcase
    end

    assert_match %{"downcase":"bar"}, @j.target!.gsub(/\s/,'')
    assert_match %{"upcase":"BAR"}, @j.target!.gsub(/\s/,'')
  end

  def test_hash_assignment
    @j.encode do
      _[:upcase] = 'BAR'
      _[:downcase] = 'bar'
    end

    assert_match %{"downcase":"bar"}, @j.target!.gsub(/\s/,'')
    assert_match %{"upcase":"BAR"}, @j.target!.gsub(/\s/,'')
  end

  def test_whole_array
    @j.encode do
      _! [1,2,3]
    end

    assert_match /^\[1,2,3\]$/, @j.target!.gsub(/\s/,'')
  end

  def test_array_shift
    @j.encode do
      _ 1
      _ 2
      _ 3
    end

    assert_match /^\[1,2,3\]$/, @j.target!.gsub(/\s/,'')
  end

  def test_array_methods
    @j.encode do
      _ 3
      _ 1
      _ nil
      _ 2
      _.compact!
      _.sort!
    end

    assert_match /^\[1,2,3\]$/, @j.target!.gsub(/\s/,'')
  end

  def test_enumerable
    @j.encode do
      _ [1,2,3] do |n|
        _! n*n
      end
    end

    assert_match /^\[1,4,9\]$/, @j.target!.gsub(/\s/,'')
  end

  def test_argument_multiple_arguments_with_block
    assert_raises ArgumentError do
      @j.encode do
        _ 1, 2, 3 do |n|
          _! n*n
        end
      end
    end
  end

  def test_argument_error_literal_after_named_value
    assert_raises ArgumentError do
      @j.encode do
        _foo 'bar'
        _ [1,2,3]
      end
    end
  end

  def test_argument_error_named_value_after_literal
    assert_raises ArgumentError do
      @j.encode do
        _ [1,2,3]
        _foo 'bar'
      end
    end
  end
end
