# explicit request types
$HTTP_GET  = ARGV.delete('--get')
$HTTP_POST = ARGV.delete('--post')
$XHR_JSON  = ARGV.delete('--json')
$TEXT      = ARGV.delete('--text')

# Only prompt if explicitly asked for
ARGV.push '' if ARGV.empty?
ARGV.delete('--prompt') or ARGV.delete('--offline')

# standard objects
$cgi = CGI.new
$param = $cgi.params

# implied request types
$HTTP_GET  ||= ($cgi.request_method == 'GET')
$HTTP_POST ||= ($cgi.request_method == 'POST')
$XHR_JSON  ||= ($cgi.accept.to_s =~ /json/)
$TEXT      ||= ($cgi.accept.to_s =~ /plain/ and $cgi.accept.to_s !~ /html/)
$XHTML     = ($cgi.accept.to_s =~ /xhtml/ or $cgi.accept == nil)

# get arguments if CGI couldn't find any... 
$param.merge!(CGI.parse(ARGV.join('&'))) if $param.empty?

module Wunderbar
  module Untaint
    def untaint_if_match regexp
      self.untaint if regexp.match(self)
    end
  end
end

# fast path for accessing CGI parameters
def $param.method_missing(name)
  if has_key? name.to_s
    if self[name.to_s].length == 1
      self[name.to_s].first.extend(Wunderbar::Untaint)
    else
      self[name.to_s].join 
    end
  end
end

$env = {}
def $env.method_missing(name)
  delete name.to_s if ENV[name.to_s] != self[name.to_s]
  if ENV[name.to_s] and not has_key?(name.to_s)
    self[name.to_s]=ENV[name.to_s].dup.extend(Wunderbar::Untaint)
  end
  self[name.to_s]
end

# quick access to request_uri
module Wunderbar
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
$USER = ENV['REMOTE_USER'] || ENV['USER'] ||
  if RUBY_PLATFORM =~ /darwin/
    `dscl . -search /Users UniqueID #{Process.uid}`.split.first
  else
    `getent passwd #{Process.uid}`.split(':').first
  end

ENV['REMOTE_USER'] ||= $USER

$HOME = ENV['HOME'] ||= File.expand_path('~' + $USER)
$SERVER = ENV['HTTP_HOST'] || `hostname`.chomp

# more implied request types
$XHR_JSON  ||= ($env.REQUEST_URI.to_s =~ /\?json$/)
$TEXT      ||= ($env.REQUEST_URI.to_s =~ /\?text$/)

# set encoding to UTF-8
ENV['LANG'] ||= "en_US.UTF-8"
if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
else
  $KCODE = 'U'
end
