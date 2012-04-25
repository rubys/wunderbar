module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 12
    TINY  = 3

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
