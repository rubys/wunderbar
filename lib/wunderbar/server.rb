at_exit do
  port = ARGV.find {|arg| arg =~ /--port=(.*)/}
  if port and ARGV.delete(port)
    port = $1.to_i

    # entry point for Rack
    def $cgi.call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
      $env = OpenStruct.new(env)
      $param = @request.params

      Wunderbar.call(env)
      @response.finish
    end

    # redirect the output produced
    def $cgi.out(headers,&block)
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
  else
    # CGI or command line
    Wunderbar.call(ENV)
  end
end
