# explicit request types
module Wunderbar
  module Options
    XHR_JSON  = ARGV.delete('--json')
    TEXT      = ARGV.delete('--text')
  end

  class Scope
    attr_accessor :env
    def initialize(env)
      @env = env
    end
  end

  @@templates = {}
  @@files = {}

  def self.templates
    @@templates
  end

  def self.files
    @@files
  end

  module API
    def _html(*args, &block)
      Wunderbar.html(*args, &block)
    end

    def _xhtml(*args, &block)
      Wunderbar.xhtml(*args, &block)
    end

    def _json(*args, &block)
      Wunderbar.json(*args, &block)
    end

    def _text(*args, &block)
      Wunderbar.text(*args, &block)
    end

    def _websocket(*args, &block)
      args.last[:sync]=args.last.fetch(:sync,true) if Hash === args.last
      Wunderbar.websocket(*args, &block)
    end

    def _template(name, &block)
      Wunderbar.templates[name.to_s.gsub('_','-')] = block
    end

    def _file(name, options={}, &block)
      options[:source] = block if block
      Wunderbar.files[name] = options
    end
  end

  #
  # Some proxies will replace server errors with their own output, and
  # some applications will want to indicate that there is useful, parseable,
  # content in controlled failures.  For this reason, allow the server
  # error responses to be customized by the application.
  #
  module ServerError
    @@status = 500
    @@text = 'Internal Server Error'

    def self.status=(status)
      @@status = status
    end

    def self.text=(text)
      @@text = text
    end

    def self.status
      @@status
    end

    def self.text
      "#{@@status} #{@@text}"
    end
  end
end

require 'socket'
$SERVER = ENV['HTTP_HOST'] || Socket::gethostname

# set encoding to UTF-8
ENV['LANG'] ||= "en_US.UTF-8"
begin
  verbose = $VERBOSE
  $VERBOSE = nil
  Encoding.default_external = Encoding::UTF_8 
  Encoding.default_internal = Encoding::UTF_8
ensure
  $VERBOSE = verbose
end

# Add methods to the 'main' object
if self.to_s == 'main'
  class << self
    include Wunderbar::API

    def env
      ENV
    end
  end
end
