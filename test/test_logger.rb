require 'test/unit'
require 'rubygems'
require 'wunderbar'
require 'logger'

class TestLogger
  attr_accessor :messages
  def initialize
    @messages = Hash.new {|hash, key| hash[key] = Array.new}
    @original_logger = Wunderbar.logger
    logger = self
    Wunderbar.instance_eval {@logger = logger}
  end

  def method_missing(method, *args)
    if [:debug, :info, :warn, :error, :fatal].include? method
      @messages[method] << args.first
    else
      @original_logger.send(method, *args)
    end
  end

  def teardown
    logger = @original_logger
    Wunderbar.instance_eval {@logger = logger}
  end
end

class LoggerTest < Test::Unit::TestCase
  def setup
    @logger = TestLogger.new
  end

  def teardown
    @logger.teardown
  end

  def test_debug
    Wunderbar.debug 'Sneezy'
    assert @logger.messages[:debug].include? 'Sneezy'
  end

  def test_info
    Wunderbar.info 'Sleepy'
    assert @logger.messages[:info].include? 'Sleepy'
  end

  def test_warn
    Wunderbar.warn 'Dopey'
    assert @logger.messages[:warn].include? 'Dopey'
  end

  def test_error
    Wunderbar.error 'Doc'
    assert @logger.messages[:error].include? 'Doc'
  end

  def test_fatal
    Wunderbar.fatal 'Happy'
    assert @logger.messages[:fatal].include? 'Happy'
  end

  def test_loglevel
    assert Wunderbar.logger.level == Logger::WARN
    Wunderbar.log_level = 'debug'
    assert Wunderbar.logger.level == Logger::DEBUG
    Wunderbar.log_level = 'info'
    assert Wunderbar.logger.level == Logger::INFO
    Wunderbar.log_level = 'warn'
    assert Wunderbar.logger.level == Logger::WARN
    Wunderbar.log_level = 'error'
    assert Wunderbar.logger.level == Logger::ERROR
    Wunderbar.log_level = 'fatal'
    assert Wunderbar.logger.level == Logger::FATAL
  end
end
