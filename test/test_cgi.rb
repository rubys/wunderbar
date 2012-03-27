require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'stringio'

class CGITest < Test::Unit::TestCase
  def setup
    @stdout = $stdout
    $stdout = StringIO.new
  end

  def teardown
    $stdout = @stdout
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
    log_level, Wunderbar.log_level = Wunderbar.log_level, 'fatal'

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
  ensure
    Wunderbar.log_level = log_level
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
      {:response => 'It Worked!'}
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
    assert_match %r{^null$}, $stdout.string
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
  ensure
    $XHR_JSON = json
  end

  def test_text_success
    text, $TEXT = $TEXT, true

    Wunderbar.text do
      puts 'It Worked!'
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
  ensure
    $TEXT = text
  end
end
