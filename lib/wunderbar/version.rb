module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 1
    MINOR = 2
    TINY  = 7

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
