require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'stringio'

class SintraTest < Test::Unit::TestCase
  def setup
    @stderr, $stderr = $stderr, StringIO.new
    Wunderbar.logger = nil
    Wunderbar.queue.clear
  end

  def teardown
    $stderr = @stderr
  end

  def test_html_success
    get '/html/success' do
      _html do
        _body
      end
    end

    assert_equal 'text/html;charset=utf-8', last_response.content_type
    assert_match %r{^\s+<body></body>$}, last_response.body
  end

  def test_html_view_no_layout
    get '/html/view/no_layout' do
      _html :no_layout, :layout => false
    end

    assert_equal 'text/html;charset=utf-8', last_response.content_type
    assert_match %r{^\s+<title>No Layout</title>$}, last_response.body
    assert_match %r{^\s+<p>From the view</p>$}, last_response.body
  end

  def test_html_view_with_layout
    get '/html/view/with_layout' do
      _html :with_layout, :layout => true
    end

    assert_equal 'text/html;charset=utf-8', last_response.content_type
    assert_match %r{^\s+<title>From the Layout</title>$}, last_response.body
    assert_match %r{^\s+<p>From the view</p>$}, last_response.body
  end

  def test_html_safe
    get '/html/safe' do
      _html do
        _p $SAFE
      end
    end

    assert_match %r{^\s+<p>1</p>$}, last_response.body
  end

  def test_html_params
    get '/html/params', {'foo' => 'bar'} do
      _html do
        _body do
          _p @foo
        end
      end
    end

    assert_match %r{^\s+<p>bar</p>$}, last_response.body
  end

  def test_html_unmodified
    get '/html/unmodified' do
      _html do
      end
    end

    assert_match %r{^"\w+"$}, last_response.headers['Etag']
    assert_equal 200, last_response.status

    get '/html/unmodified', {}, 
      {'HTTP_IF_NONE_MATCH' => last_response.headers['Etag']}
    assert_equal 304, last_response.status
  end

  def test_html_failure
    get '/html/failure' do
      _html do
        _body do
          error_undefined
        end
      end
    end

    assert_equal 500, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response.content_type
    assert_match %r{^\s+<h1>Internal Server Error</h1>$}, last_response.body
    assert_match %r{^\s+<pre.*>.*NameError.*error_undefined}, last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_html_log
    get '/html/log' do
      _html do
        _.fatal 'oh, dear'
      end
    end

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_xhtml_success
    get '/xhtml/success' do
      _xhtml do
        _body
      end
    end

    assert_equal 'application/xhtml+xml;charset=utf-8', 
      last_response.content_type
    assert_match %r{^\s+<body></body>$}, last_response.body
  end

  def test_json_success
    get '/json/success' do
      _json do
        _ :response => 'It Worked!'
      end
    end

    assert_match %r{^\s+"response": "It Worked!"}, last_response.body
    assert_equal 'application/json;charset=utf-8', last_response.content_type
  end

  def jest_json_missing
    get '/json/missing' do
      _json do
      end
    end

    assert_equal 404, last_response.status
    assert_match %r{^application/json}, last_response.content_type
    assert_match /^\{\s*\}\s*$/, last_response.body
  end

  def test_json_failure
    get '/json/failure' do
      _json do
        error_undefined
      end
    end

    assert_equal 500, last_response.status
    assert_match %r{^application/json}, last_response.content_type
    assert_match %r{^\s+"exception": ".*NameError.*error_undefined},
      last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_json_log
    get '/json/log' do
      _json do
        _.fatal 'oh, dear'
      end
    end

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_text_success
    get '/text/success' do
      _text do
        _ 'It Worked!'
      end
    end

    assert_equal 'text/plain;charset=utf-8', last_response.content_type
    assert_equal "It Worked!\n", last_response.body
  end

  def test_text_methods
    get '/text/methods' do
      _text do
        _.printf "%s Worked!\n", 'It'
      end
    end

    assert_equal 'text/plain;charset=utf-8', last_response.content_type
    assert_equal "It Worked!\n", last_response.body
  end

  def test_text_missing
    get '/text/missing' do
      _text do
      end
    end

    assert_equal 404, last_response.status
    assert_equal 'text/plain;charset=utf-8', last_response.content_type
    assert_equal '', last_response.body
  end

  def test_text_failure
    get '/text/failure' do
      _text do
        error_undefined
      end
    end

    assert_equal 500, last_response.status
    assert_match %r{^text/plain}, last_response.content_type
    assert_match %r{NameError.*error_undefined}, last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_text_log
    get '/text/log' do
      _text do
        _.fatal 'oh, dear'
      end
    end

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  begin
    require 'wunderbar/sinatra'
    require 'rack/test'
    include Rack::Test::Methods

    TestApp = Class.new(Sinatra::Base)
    TestApp.set :environment, 'production'
    TestApp.helpers Wunderbar::SinatraHelpers

    def get(path, *args, &block)
      TestApp.get(path, &block) if block
      super(path, *args, &nil)
    end

    def app
      TestApp.new
    end

  rescue LoadError

    attr_accessor :default_test
    public_instance_methods.grep(/^test_/).each do |method|
      remove_method method
    end
  end
end
