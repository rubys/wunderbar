# explicit request types
module Wunderbar
  module Options
    XHR_JSON  = ARGV.delete('--json')
    TEXT      = ARGV.delete('--text')
  end

  module Untaint
    def untaint_if_match regexp
      self.untaint if regexp.match(self)
    end
  end

  class Scope
    attr_accessor :env
    def initialize(env)
      @env = env
    end
  end
end

require 'socket'
$SERVER = ENV['HTTP_HOST'] || Socket::gethostname

# set encoding to UTF-8
ENV['LANG'] ||= "en_US.UTF-8"
if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
else
  $KCODE = 'U'
end

# Add methods to the 'main' object
if self.to_s == 'main'
  class << self
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
  end
end
