require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'stringio'

class CGITest < Test::Unit::TestCase
  def setup
    @stdout, @stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    Wunderbar.queue.clear
    Wunderbar.logger = nil
    @accept = ENV['HTTP_ACCEPT']
  end

  def teardown
    $stdout, $stderr = @stdout, @stderr
    Wunderbar.logger = nil
    ENV['HTTP_ACCEPT'] = @accept
  end

  def test_html_success
    Wunderbar.html do
      _body
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: text/html; charset=UTF-8\r\n}, $stdout.string
    assert_match %r{^Etag: "\w+"\r\n}, $stdout.string
    assert_match %r{^\s+<body></body>$}, $stdout.string
  end

  def test_html_failure
    Wunderbar.html do
      _body do
        error_undefined
      end
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{Status: 500 Internal Error\r\n}, $stdout.string
    assert_match %r{^Content-Type: text/html; charset=UTF-8\r\n}, $stdout.string
    assert_match %r{^\s+<h1>Internal Error</h1>$}, $stdout.string
    assert_match %r{^\s+<pre>.*NameError.*error_undefined}, $stdout.string
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_html_log
    Wunderbar.html do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(ENV)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_xhtml_success
    ENV['HTTP_ACCEPT'] = 'application/xhtml+xml'

    Wunderbar.xhtml do
      _body
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: application/xhtml\+xml; charset=UTF-8\r\n},
      $stdout.string
    assert_match %r{^\s+<body></body>$}, $stdout.string
  end

  def test_xhtml_fallback
    ENV['HTTP_ACCEPT'] = 'text/html'

    Wunderbar.xhtml do
      _body
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: text/html; charset=UTF-8\r\n}, $stdout.string
    assert_match %r{^\s+<body></body>$}, $stdout.string
  end

  def test_json_success
    ENV['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      _ :response => 'It Worked!'
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match %r{^\s+"response": "It Worked!"}, $stdout.string
  end

  def test_json_missing
    ENV['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{Status: 404 Not Found\r\n}, $stdout.string
    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match /^\{\s*\}\s*$/, $stdout.string
  end

  def test_json_failure
    ENV['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      error_undefined
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{Status: 500 Internal Server Error\r\n}, $stdout.string
    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match %r{^\s+"exception": ".*NameError.*error_undefined}, 
      $stdout.string
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_json_log
    ENV['HTTP_ACCEPT'] = 'application/json'

    Wunderbar.json do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(ENV)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_text_success
    ENV['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _ 'It Worked!'
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: text/plain; charset=UTF-8\r\n}, 
      $stdout.string
    assert_match %r{\r\n\r\nIt Worked!\n\Z}, $stdout.string
  end

  def test_text_methods
    ENV['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _.printf "%s Worked!\n", 'It'
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{^Content-Type: text/plain}, $stdout.string
    assert_match %r{\r\n\r\nIt Worked!\n\Z}, $stdout.string
  end

  def test_text_missing
    ENV['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{Status: 404 Not Found\r\n}, $stdout.string
    assert_match %r{^Content-Type: text/plain}, $stdout.string
    assert_match %r{\r\n\r\n\Z}, $stdout.string
  end

  def test_text_failure
    ENV['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      error_undefined
    end

    Wunderbar::CGI.call(ENV)

    assert_match %r{Status: 500 Internal Server Error\r\n}, $stdout.string
    assert_match %r{^Content-Type: text/plain}, $stdout.string
    assert_match %r{NameError.*error_undefined}, $stdout.string
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  end

  def test_text_log
    ENV['HTTP_ACCEPT'] = 'text/plain'

    Wunderbar.text do
      _.fatal 'oh, dear'
    end

    Wunderbar::CGI.call(ENV)

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end
end
