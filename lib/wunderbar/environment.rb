# explicit request types
module Wunderbar
  module Options
    XHR_JSON  = ARGV.delete('--json')
    TEXT      = ARGV.delete('--text')
  end

  @@unsafe = false

  def self.unsafe!(mode=true)
    @@unsafe=mode
  end

  def self.safe?
    if $SAFE == 0 and not @@unsafe
      # some gems (e.g. em-websocket-0.3.6) insert unsafe entries into the
      # path, and that prevents requires from succeeding.  If it looks like
      # we are about to make a transition to $SAFE=1, clean up that mess
      # before proceeding.
      #
      # the goal of $SAFE is not to protect us against software which was
      # installed by the owner of the site, but from injection attacks
      # contained within data provided by users of the site.
      $:.each_with_index do |path, index|
        if path.tainted?
          $:[index] = File.expand_path(path.untaint).untaint
        end
      end
    end

    not @@unsafe
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

    def _websocket(*args, &block)
      args.last[:sync]=args.last.fetch(:sync,true) if Hash === args.last
      Wunderbar.websocket(*args, &block)
    end

    def env
      ENV
    end
  end
end
