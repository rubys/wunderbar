module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 18
    TINY  = 2

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
