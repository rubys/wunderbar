require 'logger'

module Wunderbar
  def self.logger
    @logger ||= nil
    return @logger if @logger
    @logger = Logger.new($stderr)
    @logger.level = Logger::WARN
    @logger.formatter = proc { |severity, datetime, progname, msg|
      "_#{severity} #{msg}\n"
    }
    @logger
  end

  def self.logger= new_logger
    @logger = new_logger
  end

  def self.log_level=(level)
    return unless level

    case level.to_s.downcase
    when 'debug'; logger.level = Logger::DEBUG
    when 'info';  logger.level = Logger::INFO
    when 'warn';  logger.level = Logger::WARN
    when 'error'; logger.level = Logger::ERROR
    when 'fatal'; logger.level = Logger::FATAL
    else
      warn "Invalid log_level specified: #{level}"
    end
  end

  def self.default_log_level=(level)
    self.log_level = level unless @logger
  end

  def self.log_level
    return 'debug' if logger.level == Logger::DEBUG
    return 'info'  if logger.level == Logger::INFO
    return 'warn'  if logger.level == Logger::WARN
    return 'error' if logger.level == Logger::ERROR
    return 'fatal' if logger.level == Logger::FATAL
  end

  # convenience methods
  def self.debug(*args, &block)
    logger.debug(*args, &block)
  end

  def self.info(*args, &block)
    logger.info(*args, &block)
  end

  def self.warn(*args, &block)
    logger.warn(*args, &block)
  end

  def self.error(*args, &block)
    logger.error(*args, &block)
  end

  def self.fatal(*args, &block)
    logger.fatal(*args, &block)
  end
end

Wunderbar.log_level = :debug  if ARGV.delete '--debug'
Wunderbar.log_level = :info   if ARGV.delete '--info'
Wunderbar.log_level = :warn   if ARGV.delete '--warn'
Wunderbar.log_level = :error  if ARGV.delete '--error'
Wunderbar.log_level = :fatal  if ARGV.delete '--fatal'
