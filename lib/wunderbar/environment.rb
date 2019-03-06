# explicit request types
module Wunderbar
  module Options
    XHR_JSON  = ARGV.delete('--json')
    TEXT      = ARGV.delete('--text')
  end

  # Ruby 2.6.0 gets rid of $SAFE > 1; unfortunately in the process it
  # treats $SAFE = 1 as a higher level; @FAFE = 1 no longer is limited
  # to taintness checks, it not treats all File operations as unsafe
  @@unsafe = (RUBY_VERSION.split('.').map(&:to_i) <=> [2, 6, 0]) == 1

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
          $:[index] = File.expand_path(path.dup.untaint).untaint
        end
      end

      # avoid: "Insecure PATH - (SecurityError)" when using Bundler
      if defined? Bundler
        ENV['PATH'] = ENV['PATH'].dup.untaint
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
