require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'stringio'

class CGITest < Test::Unit::TestCase
  def setup
    @stdout, @stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    Wunderbar.logger = nil
  end

  def teardown
    $stdout, $stderr = @stdout, @stderr
    Wunderbar.logger = nil
  end

  def test_html_success
    Wunderbar.html do
      _body
    end

    Wunderbar.evaluate

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

    Wunderbar.evaluate

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

    Wunderbar.evaluate

    assert_equal "_FATAL oh, dear\n", $stderr.string
  end

  def test_xhtml_success
    xhtml, $XHTML = $XHTML, true

    Wunderbar.xhtml do
      _body
    end

    Wunderbar.evaluate

    assert_match %r{^Content-Type: application/xhtml\+xml; charset=UTF-8\r\n},
      $stdout.string
    assert_match %r{^\s+<body></body>$}, $stdout.string
  ensure
    $XHTML = xhtml
  end

  def test_xhtml_fallback
    xhtml, $XHTML = $XHTML, false

    Wunderbar.xhtml do
      _body
    end

    Wunderbar.evaluate

    assert_match %r{^Content-Type: text/html; charset=UTF-8\r\n}, $stdout.string
    assert_match %r{^\s+<body></body>$}, $stdout.string
  ensure
    $XHTML = xhtml
  end

  def test_json_success
    json, $XHR_JSON = $XHR_JSON, true

    Wunderbar.json do
      _ :response => 'It Worked!'
    end

    Wunderbar.evaluate

    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match %r{^\s+"response": "It Worked!"}, $stdout.string
  ensure
    $XHR_JSON = json
  end

  def test_json_missing
    json, $XHR_JSON = $XHR_JSON, true

    Wunderbar.json do
    end

    Wunderbar.evaluate

    assert_match %r{Status: 404 Not Found\r\n}, $stdout.string
    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match /^\{\s*\}\s*$/, $stdout.string
  ensure
    $XHR_JSON = json
  end

  def test_json_failure
    json, $XHR_JSON = $XHR_JSON, true

    Wunderbar.json do
      error_undefined
    end

    Wunderbar.evaluate

    assert_match %r{Status: 500 Internal Error\r\n}, $stdout.string
    assert_match %r{^Content-Type: application/json\r\n}, $stdout.string
    assert_match %r{^\s+"exception": ".*NameError.*error_undefined}, 
      $stdout.string
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  ensure
    $XHR_JSON = json
  end

  def test_json_log
    json, $XHR_JSON = $XHR_JSON, true

    Wunderbar.json do
      _.fatal 'oh, dear'
    end

    Wunderbar.evaluate

    assert_equal "_FATAL oh, dear\n", $stderr.string
  ensure
    $XHR_JSON = json
  end

  def test_text_success
    text, $TEXT = $TEXT, true

    Wunderbar.text do
      _ 'It Worked!'
    end

    Wunderbar.evaluate

    assert_match %r{^Content-Type: text/plain\r\n}, $stdout.string
    assert_match %r{\r\n\r\nIt Worked!\n\Z}, $stdout.string
  ensure
    $TEXT = text
  end

  def test_text_methods
    text, $TEXT = $TEXT, true

    Wunderbar.text do
      _.printf "%s Worked!\n", 'It'
    end

    Wunderbar.evaluate

    assert_match %r{^Content-Type: text/plain\r\n}, $stdout.string
    assert_match %r{\r\n\r\nIt Worked!\n\Z}, $stdout.string
  ensure
    $TEXT = text
  end

  def test_text_missing
    text, $TEXT = $TEXT, true

    Wunderbar.text do
    end

    Wunderbar.evaluate

    assert_match %r{Status: 404 Not Found\r\n}, $stdout.string
    assert_match %r{^Content-Type: text/plain\r\n}, $stdout.string
    assert_match %r{\r\n\r\n\Z}, $stdout.string
  ensure
    $TEXT = text
  end

  def test_text_failure
    text, $TEXT = $TEXT, true

    Wunderbar.text do
      error_undefined
    end

    Wunderbar.evaluate

    assert_match %r{Status: 500 Internal Error\r\n}, $stdout.string
    assert_match %r{^Content-Type: text/plain\r\n}, $stdout.string
    assert_match %r{NameError.*error_undefined}, $stdout.string
    assert_match %r{^_ERROR.*NameError.*error_undefined}, $stderr.string
  ensure
    $TEXT = text
  end

  def test_text_log
    text, $TEXT = $TEXT, true

    Wunderbar.text do
      _.fatal 'oh, dear'
    end

    Wunderbar.evaluate

    assert_equal "_FATAL oh, dear\n", $stderr.string
  ensure
    $TEXT = text
  end

end
