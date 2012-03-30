module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 8
    TINY  = 14

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
