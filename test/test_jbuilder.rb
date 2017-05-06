require 'minitest/autorun'
require 'wunderbar'

# these tests were "borrowed"/adapted from jbuilder so as to demonstrate
# functional parity:
#   https://github.com/rails/jbuilder/blob/master/test/jbuilder_test.rb

class JbuilderTest < MiniTest::Test
  def setup
    @j = Wunderbar::JsonBuilder.new(Struct.new(:params).new({}))
  end

  def test_single_key
    parsed = @j.encode do
      _content "hello"
    end
    
    assert_equal "hello", parsed["content"]
  end

  def test_single_key_with_false_value
    parsed = @j.encode do
      _content false
    end

    assert_equal false, parsed["content"]
  end

  def test_single_key_with_nil_value
    parsed = @j.encode do
      _content nil
    end

    assert parsed.has_key?("content")
    assert_nil parsed["content"]
  end

  def test_multiple_keys
    parsed = @j.encode do
      _title "hello"
      _content "world"
    end
    
    assert_equal "hello", parsed["title"]
    assert_equal "world", parsed["content"]
  end
  
  def test_extracting_from_object
    person = Struct.new(:name, :age).new("David", 32)
    
    parsed = @j.encode do
      _ person, :name, :age
    end
    
    assert_equal "David", parsed["name"]
    assert_equal 32, parsed["age"]
  end
  
  def test_nesting_single_child_with_block
    parsed = @j.encode do
      _author do
        _name "David"
        _age  32
      end
    end
    
    assert_equal "David", parsed["author"]["name"]
    assert_equal 32, parsed["author"]["age"]
  end
  
  def test_nesting_multiple_children_with_block
    parsed = @j.encode do
      _comments do
        _ { _content "hello" }
        _ { _content "world" }
      end
    end

    assert_equal "hello", parsed["comments"][0]["content"]
    assert_equal "world", parsed["comments"][1]["content"]
  end
  
  def test_nesting_single_child_with_inline_extract
    person = Class.new do
      attr_reader :name, :age
      
      def initialize(name, age)
        @name, @age = name, age
      end
    end.new("David", 32)
    
    parsed = @j.encode do
      _author person, :name, :age
    end
    
    assert_equal "David", parsed["author"]["name"]
    assert_equal 32,      parsed["author"]["age"]
  end
  
  def test_nesting_multiple_children_from_array
    comments = [ Struct.new(:content, :id).new("hello", 1), 
                 Struct.new(:content, :id).new("world", 2) ]
    
    parsed = @j.encode do
      _comments comments, :content
    end
    
    assert_equal ["content"], parsed["comments"].first.keys
    assert_equal "hello", parsed["comments"][0]["content"]
    assert_equal "world", parsed["comments"][1]["content"]
  end
  
  def test_nesting_multiple_children_from_array_when_child_array_is_empty
    comments = []
    
    parsed = @j.encode do
      _name "Parent"
      _comments comments, :content
    end
    
    assert_equal "Parent", parsed["name"]
    assert_equal [], parsed["comments"]
  end
  
  def test_nesting_multiple_children_from_array_with_inline_loop
    comments = [ Struct.new(:content, :id).new("hello", 1), 
                 Struct.new(:content, :id).new("world", 2) ]
    
    parsed = @j.encode do
      _comments comments do |comment|
        _content comment.content
      end
    end
    
    assert_equal ["content"], parsed["comments"].first.keys
    assert_equal "hello", parsed["comments"][0]["content"]
    assert_equal "world", parsed["comments"][1]["content"]
  end

  def test_nesting_multiple_children_from_array_with_inline_loop_on_root
    comments = [ Struct.new(:content, :id).new("hello", 1), Struct.new(:content, :id).new("world", 2) ]
    
    parsed = @j.encode do
      _ comments do |comment|
        _content comment.content
      end
    end
    
    assert_equal "hello", parsed[0]["content"]
    assert_equal "world", parsed[1]["content"]
  end
  
  def test_array_nested_inside_nested_hash
    parsed = @j.encode do
      _author do
        _name "David"
        _age  32
        
        _comments do
          _ { _content "hello" }
          _ { _content "world" }
        end
      end
    end
    
    assert_equal "hello", parsed["author"]["comments"][0]["content"]
    assert_equal "world", parsed["author"]["comments"][1]["content"]
  end
  
  def test_array_nested_inside_array
    parsed = @j.encode do
      _comments do
        _ do
          _authors do
            _ do
              _name "david"
            end
          end
        end
      end
    end
    
    assert_equal "david", parsed["comments"].first["authors"].first["name"]
  end
  
  def test_top_level_array
    comments = [ Struct.new(:content, :id).new("hello", 1), 
                 Struct.new(:content, :id).new("world", 2) ]

    parsed = @j.encode do
      _ comments do |comment|
        _content comment.content
      end
    end
    
    assert_equal "hello", parsed[0]["content"]
    assert_equal "world", parsed[1]["content"]
  end 
  
  def test_empty_top_level_array
    comments = []
    
    parsed = @j.encode do
      _ comments do |comment|
        _content comment.content
      end
    end
    
    assert_equal [], parsed
  end
  
  def test_dynamically_set_a_key_value
    parsed = @j.encode do
      _["each"] = "stuff"
    end
    
    assert_equal "stuff", parsed["each"]
  end

  def test_dynamically_set_a_key_nested_child_with_block
    parsed = @j.encode do
      _ :author do
        _name "David"
        _age 32
      end
    end
    
    assert_equal "David", parsed["author"]["name"]
    assert_equal 32, parsed["author"]["age"]
  end
end
