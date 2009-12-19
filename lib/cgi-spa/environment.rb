# explicit request types
$HTTP_GET  = ARGV.delete('--html')
$HTTP_POST = ARGV.delete('--post')
$XHR_JSON  = ARGV.delete('--json')
$XHTML     = ARGV.delete('--xhtml')

# Only prompt if explicitly asked for
ARGV.push '' if ARGV.empty?
ARGV.delete('--prompt') or ARGV.delete('--offline')

# standard objects
$cgi = CGI.new
$param = $cgi.params
$x = Builder::XmlMarkup.new :indent => 2

# implied request types
$HTTP_GET  ||= ($cgi.request_method == 'GET')
$HTTP_POST ||= ($cgi.request_method == 'POST')
$XHR_JSON  ||= ($cgi.accept.to_s =~ /json/)
$XHTML     ||= ($cgi.accept.to_s =~ /xhtml/)

# get arguments if CGI couldn't find any... 
$param.merge!(CGI.parse(ARGV.join('&'))) if $param.empty?

# fast path for accessing CGI parameters
def $param.method_missing(name)
  self[name.to_s].join if has_key? name.to_s
end

# quick access to request_uri
SELF = ENV['REQUEST_URI'].to_s
def SELF?
  SELF + "?" # avoids spoiling the cache
end

# environment objects
$USER = ENV['USER'] ||
  if RUBY_PLATFORM =~ /darwin/
    `dscl . -search /Users UniqueID #{Process.uid}`.split.first
  else
    `getent passwd #{Process.uid}`.split(':').first
  end

$HOME   = ENV['HOME'] || File.expand_path('~' + $USER)
$SERVER = ENV['HTTP_HOST'] || `hostname`.chomp
