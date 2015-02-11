require 'minitest/autorun'
require 'wunderbar'
require 'stringio'

class CGITest < Minitest::Test
  def setup
    @stderr, $stderr = $stderr, StringIO.new

    Wunderbar.queue.clear
    Wunderbar.logger = nil

    @cgi = Struct.new(:env, :params, :headers, :body).new(Hash[ENV], {}, {}, '')
    def @cgi.out(headers, &block)
      self.headers = headers
      self.body = block.call
    end
  end
  
  def teardown
    $stderr = @stderr
    Wunderbar.logger = nil
  end

  def test_html_success
    Wunderbar.html do
      _p 'success'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'text/html', @cgi.headers['type']
    assert_equal 'UTF-8', @cgi.headers['charset']
    assert_match %r{^\s+<p>success</p>$}, @cgi.body
  end

  def test_html_safe
    Wunderbar.html do
      _p $SAFE
    end

    Proc.new { $SAFE=1 if $SAFE==0; Wunderbar::CGI.call(@cgi) }.call

    assert_match %r{^\s+<p>1</p>$}, @cgi.body
  end

  def test_html_params
    Wunderbar.html do
      _body do
        _p @foo
      end
    end

    @cgi.params['foo'] = ['bar']
    Wunderbar::CGI.call(@cgi)

    assert_match %r{^\s+<p>bar</p>$}, @cgi.body
  end

  def test_html_unmodified
    Wunderbar.html do
    end

    Wunderbar::CGI.call(@cgi)

    assert_match %r{^"\w+"$}, @cgi.headers['Etag']
    assert_equal nil, @cgi.headers['status']

    @cgi.env['HTTP_IF_NONE_MATCH'] = @cgi.headers['Etag']

    Wunderbar::CGI.call(@cgi)
    assert_equal '304 Not Modified', @cgi.headers['status']
  end

  def test_html_failure
    Wunderbar.html do
      _body do
        error_undefined
      end
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal '500 Internal Server Error', @cgi.headers['status']
    assert_equal 'text/html', @cgi.headers['type']
    assert_equal 'UTF-8', @cgi.headers['charset']
    assert_match %r{^\s+<h1>Internal Server Error</h1>$}, @cgi.body
    assert_match %r{^\s+<pre.*>.*NameError.*error_undefined}, @cgi.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
    refute_match %r{>\s*<!DOCTYPE}, @cgi.body
  end

  def test_html_log
    Wunderbar.html do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_xhtml_success
    @cgi.env['HTTP_ACCEPT'] = 'application/xhtml+xml'

    Wunderbar.xhtml do
      _p 'success'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'application/xhtml+xml', @cgi.headers['type']
    assert_equal 'UTF-8', @cgi.headers['charset']
    assert_match %r{^\s+<p>success</p>$}, @cgi.body
  end

  def test_xhtml_fallback
    @cgi.env['HTTP_ACCEPT'] = 'text/html'

    Wunderbar.xhtml do
      _p 'success'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'text/html', @cgi.headers['type']
    assert_equal 'UTF-8', @cgi.headers['charset']
    assert_match %r{^\s+<p>success</p>$}, @cgi.body
  end

  def test_json_success
    @cgi.env['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      _ :response => 'It Worked!'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'application/json', @cgi.headers['type']
    assert_match %r{^\s+"response": "It Worked!"}, @cgi.body
  end

  def test_json_missing
    @cgi.env['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal '404 Not Found', @cgi.headers['status']
    assert_equal 'application/json', @cgi.headers['type']
    assert_match /^\{\s*\}\s*$/, @cgi.body
  end

  def test_json_failure
    @cgi.env['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      error_undefined
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal '500 Internal Server Error', @cgi.headers['status']
    assert_equal 'application/json', @cgi.headers['type']
    assert_match %r{^\s+"exception": ".*NameError.*error_undefined}, @cgi.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_json_log
    @cgi.env['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_text_success
    @cgi.env['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _ 'It Worked!'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'text/plain', @cgi.headers['type']
    assert_equal 'UTF-8', @cgi.headers['charset']
    assert_equal "It Worked!\n", @cgi.body
  end

  def test_text_methods
    @cgi.env['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _.printf "%s Worked!\n", 'It'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal 'text/plain', @cgi.headers['type']
    assert_equal "It Worked!\n", @cgi.body
  end

  def test_text_missing
    @cgi.env['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal '404 Not Found', @cgi.headers['status']
    assert_equal 'text/plain', @cgi.headers['type']
    assert_equal '', @cgi.body
  end

  def test_text_failure
    @cgi.env['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      error_undefined
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal '500 Internal Server Error', @cgi.headers['status']
    assert_equal 'text/plain', @cgi.headers['type']
    assert_match %r{NameError.*error_undefined}, @cgi.body
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_text_log
    @cgi.env['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(@cgi)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end
end
