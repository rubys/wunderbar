module Wunderbar
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 21
    TINY  = 0

    STRING = [MAJOR, MINOR, TINY].join('.')
  end
end unless defined?(Wunderbar::VERSION)
