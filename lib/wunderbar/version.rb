module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 16
    TINY  = 7

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
