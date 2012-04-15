module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 10
    TINY  = 4

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
