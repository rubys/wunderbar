require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'stringio'

class RackTest < Test::Unit::TestCase
  def setup
    @stderr, $stderr = $stderr, StringIO.new
    Wunderbar.queue.clear
  end

  def teardown
    $stderr = @stderr
  end

  def test_html_success
    Wunderbar.html do
      _body
    end

    get '/'

    assert_equal 'text/html; charset=UTF-8', last_response.content_type
    assert_match %r{^\s+<body></body>$}, last_response.body
  end

  def test_html_safe
    Wunderbar.html do
      _p $SAFE
    end

    get '/'

    assert_match %r{^\s+<p>1</p>$}, last_response.body
  end

  def test_html_params
    Wunderbar.html do
      _body do
        _p @foo
      end
    end

    get '/', {'foo' => 'bar'}

    assert_match %r{^\s+<p>bar</p>$}, last_response.body
  end

  def test_html_unmodified
    Wunderbar.html do
    end

    get '/'

    assert_match %r{^"\w+"$}, last_response.headers['Etag']
    assert_equal 200, last_response.status

    get '/', {}, {'HTTP_IF_NONE_MATCH' => last_response.headers['Etag']}
    assert_equal 304, last_response.status
  end

  def test_html_failure
    Wunderbar.html do
      _body do
        error_undefined
      end
    end

    get '/'

    assert_equal 500, last_response.status
    assert_equal 'text/html; charset=UTF-8', last_response.content_type
    assert_match %r{^\s+<h1>Internal Server Error</h1>$}, last_response.body
    assert_match %r{^\s+<pre.*>.*NameError.*error_undefined}, last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_html_log
    Wunderbar.html do
      _.fatal 'oh, dear'
    end

    get '/'

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_xhtml_success
    Wunderbar.xhtml do
      _body
    end

    get '/', {}, {'HTTP_ACCEPT' => 'application/xhtml+xml'}

    assert_equal 'application/xhtml+xml; charset=UTF-8', 
      last_response.content_type
    assert_match %r{^\s+<body></body>$}, last_response.body
  end

  def test_xhtml_fallback
    Wunderbar.xhtml do
      _body
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/html'}

    assert_equal 'text/html; charset=UTF-8', last_response.content_type
    assert_match %r{^\s+<body></body>$}, last_response.body
  end

  def test_json_success
    Wunderbar.json do
      _ :response => 'It Worked!'
    end

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal 'application/json; charset=UTF-8', last_response.content_type
    assert_match %r{^\s+"response": "It Worked!"}, last_response.body
  end

  def test_json_missing
    Wunderbar.json do
    end

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal 404, last_response.status
    assert_equal 'application/json; charset=UTF-8', last_response.content_type
    assert_match /^\{\s*\}\s*$/, last_response.body
  end

  def test_json_failure
    Wunderbar.json do
      error_undefined
    end

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal 500, last_response.status
    assert_equal 'application/json; charset=UTF-8', last_response.content_type
    assert_match %r{^\s+"exception": ".*NameError.*error_undefined},
      last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_json_log
    Wunderbar.json do
      _.fatal 'oh, dear'
    end

    get '/', {}, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_text_success
    Wunderbar.text do
      _ 'It Worked!'
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 'text/plain; charset=UTF-8', last_response.content_type
    assert_equal "It Worked!\n", last_response.body
  end

  def test_text_methods
    Wunderbar.text do
      _.printf "%s Worked!\n", 'It'
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 'text/plain; charset=UTF-8', last_response.content_type
    assert_equal "It Worked!\n", last_response.body
  end

  def test_text_missing
    Wunderbar.text do
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 404, last_response.status
    assert_equal 'text/plain; charset=UTF-8', last_response.content_type
    assert_equal '', last_response.body
  end

  def test_text_failure
    Wunderbar.text do
      error_undefined
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 500, last_response.status
    assert_equal 'text/plain; charset=UTF-8', last_response.content_type
    assert_match %r{NameError.*error_undefined}, last_response.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_text_log
    Wunderbar.text do
      _.fatal 'oh, dear'
    end

    get '/', {}, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  begin
    require 'wunderbar/rack'
    require 'rack/test'
    include Rack::Test::Methods

    def app
      Wunderbar::RackApp.new
    end

  rescue LoadError => exception

    attr_accessor :default_test
    public_instance_methods.grep(/^test_/).each do |method|
      remove_method method
    end
    unless instance_methods.grep(/^skip$/).empty?
      define_method(:test_rack) {skip exception.inspect}
    end
  end
end
