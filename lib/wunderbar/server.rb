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
    Wunderbar.call(ENV)
  end
end
