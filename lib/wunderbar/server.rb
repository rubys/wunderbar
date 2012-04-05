at_exit do
  # Only prompt if explicitly asked for
  ARGV.push '' if ARGV.empty?
  ARGV.delete('--prompt') or ARGV.delete('--offline')

  $cgi = CGI.new

  port = ARGV.find {|arg| arg =~ /--port=(.*)/}
  if port and ARGV.delete(port)
    port = $1.to_i

    # entry point for Rack
    def $cgi.call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
      $env = OpenStruct.new(env)
      $params = @request.params

      Wunderbar::CGI.call(env)
      @response.finish
    end

    # redirect the output produced
    def $cgi.out(headers,&block)
      status = headers.delete('status')
      @response.status = status if status

      headers = Wunderbar::CGI.headers(headers)
      headers.each { |key, value| @response[key] = value }

      @response.write block.call unless @request.head?
    end

    # Evaluate optional data from the script (after __END__)
    eval Wunderbar.data if Object.const_defined? :DATA

    # start the server
    require 'rack'
    require 'rack/showexceptions'
    app = Rack::ShowExceptions.new(Rack::Lint.new($cgi))
    Rack::Server.start :app => app, :Port => port

  elsif defined? Sinatra

    Tilt.register :_html,  Wunderbar
    Tilt.register :_xhtml, Wunderbar
    Tilt.register :_json,  Wunderbar
    Tilt.register :_text,  Wunderbar

    # redirect the output produced
    def $cgi.out(headers,&block)
      status = headers.delete('status')
      $sinatra.status status if status
      $sinatra.headers Wunderbar::CGI.headers(headers)
      $sinatra.body block.call unless $sinatra.request.head?
    end

    require 'thread'

    def $cgi.helper(sinatra, &block)
      return @semaphore = Mutex.new unless sinatra

      @semaphore.synchronize do
        $sinatra = sinatra
        $params = sinatra.params
        $env = OpenStruct.new(sinatra.env)
        Wunderbar.queue.clear
        block.call
        Wunderbar::CGI.call($env)
      end
    end

    $cgi.helper(nil) # allocate semaphore

    # define helpers
    helpers do
      def _html(*args, &block)
        $cgi.helper(self) do
          Wunderbar.html(*args, &block)
        end
      end

      def _xhtml(*args, &block)
        $cgi.helper(self) do
          Wunderbar.xhtml(*args, &block)
        end
      end

      def _json(*args, &block)
        $cgi.helper(self) do
          Wunderbar.json(*args, &block)
        end
      end

      def _text(*args, &block)
        $cgi.helper(self) do
          Wunderbar.text(*args, &block)
        end
      end
    end

  else

    # allow the REQUEST_METHOD to be set for command line invocations
    ENV['REQUEST_METHOD'] ||= 'POST' if ARGV.delete('--post')
    ENV['REQUEST_METHOD'] ||= 'GET'  if ARGV.delete('--get')

    # standard objects
    $params = $cgi.params

    # get arguments if CGI couldn't find any... 
    $params.merge!(CGI.parse(ARGV.join('&'))) if $params.empty?

    # fast path for accessing CGI parameters
    def $params.method_missing(name)
      if has_key? name.to_s
        if self[name.to_s].length == 1
          self[name.to_s].first.extend(Wunderbar::Untaint)
        else
          self[name.to_s].join 
        end
      end
    end

    # CGI or command line
    Wunderbar::CGI.call(ENV)
  end
end
