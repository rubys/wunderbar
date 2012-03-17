# produce json
def $cgi.json(&block)
  return unless $XHR_JSON
  $param.each {|key,value| instance_variable_set "@#{key}", value.first}
  output = instance_eval(&block)
rescue Exception => exception
  Kernel.print "Status: 500 Internal Error\r\n"
  output = {
    :exception => exception.inspect,
    :backtrace => exception.backtrace
  }
ensure
  if $XHR_JSON
    Kernel.print "Status: 404 Not Found\r\n" unless output
    $cgi.out? 'type' => 'application/json', 'Cache-Control' => 'no-cache' do
      begin
        JSON.pretty_generate(output)+ "\n"
      rescue
        output.to_json + "\n"
      end
    end
  end
end

# produce json and quit
def $cgi.json! &block
  return unless $XHR_JSON
  json(&block)
  Process.exit
end

# produce text
def $cgi.text &block
  return unless $TEXT
  @output = []
  def $cgi.puts(line='')
    @output << line + "\n"
  end
  def $cgi.print(line=nil)
    @output << line
  end
  $param.each {|key,value| instance_variable_set "@#{key}", value.first}
  self.instance_eval &block
rescue Exception => exception
  Kernel.print "Status: 500 Internal Error\r\n"
  @output << "\n" unless @output.empty?
  @output << exception.inspect + "\n"
  exception.backtrace.each {|frame| @output << "  #{frame}\n"}
ensure
  class << $cgi
    undef puts
    undef print
  end
  if $TEXT
    Kernel.print "Status: 404 Not Found\r\n" if @output.empty?
    $cgi.out? 'type' => 'text/plain', 'Cache-Control' => 'no-cache' do
      @output.join
    end
    @output = nil
  end
end

# produce text and quit
def $cgi.text! &block
  return unless $TEXT
  json(&block)
  Process.exit
end

# Conditionally provide output, based on ETAG
def $cgi.out?(headers, &block)
  content = block.call
  require 'digest/md5'
  etag = Digest::MD5.hexdigest(content)

  if ENV['HTTP_IF_NONE_MATCH'] == etag.inspect
    Kernel.print "Status: 304 Not Modified\r\n\r\n"
  else
    $cgi.out headers.merge('Etag' => etag.inspect) do
      content
    end
  end
end

# produce html/xhtml
def $cgi.html(*args, &block)
  return if $XHR_JSON or $TEXT
  args << {} if args.empty?
  args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml' if Hash === args.first
  mimetype = ($XHTML ? 'application/xhtml+xml' : 'text/html')
  x = HtmlMarkup.new
  $cgi.out? 'type' => mimetype, 'charset' => 'UTF-8' do
    x._! "\xEF\xBB\xBF"
    x._.declare :DOCTYPE, :html
    x.html *args, &block
  end
end

# produce html and quit
def $cgi.html! *args, &block
  return if $XHR_JSON or $TEXT
  html(*args, &block)
  Process.exit
end

# post specific logic (doesn't produce output)
def $cgi.post
  yield if $HTTP_POST
end

# post specific content (produces output)
def $cgi.post! &block
  html!(&block) if $HTTP_POST
end

# canonical interface
module Wunderbar
  def self.html(*args, &block)
    $cgi.html!(*args, &block)
  end

  def self.json(*args, &block)
    $cgi.json!(*args, &block)
  end

  def self.text(*args, &block)
    $cgi.text!(*args, &block)
  end
end

