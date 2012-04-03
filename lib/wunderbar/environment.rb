# explicit request types
module Wunderbar
  module Options
    HTTP_GET  = ARGV.delete('--get')
    HTTP_POST = ARGV.delete('--post')
    XHR_JSON  = ARGV.delete('--json')
    TEXT      = ARGV.delete('--text')
  end

  module Untaint
    def untaint_if_match regexp
      self.untaint if regexp.match(self)
    end
  end

  # quick access to request_uri
  def self.SELF 
    $env.REQUEST_URI
  end

  def self.SELF?
    if SELF '?'
      self.self
    else
      SELF + "?" # avoids spoiling the cache
    end
  end
end

# environment objects
$env = {}
def $env.method_missing(name)
  delete name.to_s if ENV[name.to_s] != self[name.to_s]
  if ENV[name.to_s] and not has_key?(name.to_s)
    self[name.to_s]=ENV[name.to_s].dup.extend(Wunderbar::Untaint)
  end
  self[name.to_s]
end

require 'socket'
$SERVER = ENV['HTTP_HOST'] || Socket::gethostname
$HOME = ENV['HOME'] ||= File.expand_path("~#{Etc.getlogin}")

# set encoding to UTF-8
ENV['LANG'] ||= "en_US.UTF-8"
if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
else
  $KCODE = 'U'
end
