# http://rack.rubyforge.org/doc/classes/Rack/Request.html
# http://rubydoc.info/gems/sinatra/Sinatra/Application
# http://www.ruby-doc.org/stdlib-1.9.3/libdoc/cgi/rdoc/CGI.html#public-class-method-details

at_exit do
  # Only prompt if explicitly asked for
  ARGV.push '' if ARGV.empty?
  ARGV.delete('--prompt') or ARGV.delete('--offline')

  cgi = CGI.new

  port = ARGV.find {|arg| arg =~ /--port=(.*)/}
  if port and ARGV.delete(port)
    port = $1.to_i

    # entry point for Rack
    def cgi.call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new

      @request.instance_variable_set '@_env', env
      @request.instance_variable_set '@_response', @response

      class << @request
        def env
          @_env
        end

        def response
          @_response
        end

        # redirect the output produced
        def out(headers,&block)
          status = headers.delete('status')
          @_response.status = status if status

          headers = Wunderbar::CGI.headers(headers)
          headers.each {|key, value| @_response[key] = value}

          @_response.write block.call unless head?
        end
      end

      Wunderbar::CGI.call(@request)
      @response.finish
    end

    # Evaluate optional data from the script (after __END__)
    eval Wunderbar.data if Object.const_defined? :DATA

    # start the server
    require 'rack'
    require 'rack/showexceptions'
    app = Rack::ShowExceptions.new(Rack::Lint.new(cgi))
    Rack::Server.start :app => app, :Port => port

  elsif defined? Sinatra

    require 'wunderbar/template'
    Tilt.register '_html',  Wunderbar::Template::Html
    Tilt.register '_xhtml', Wunderbar::Template::Xhtml
    Tilt.register '_json',  Wunderbar::Template::Json
    Tilt.register '_text',  Wunderbar::Template::Text

    # define helpers
    helpers do
      def _html(*args, &block)
        if block
          Wunderbar::Template::Html.evaluate('_html', self) do
            _html(*args) { instance_eval &block }
          end
        else
          Wunderbar::Template::Html.evaluate('_html', self, *args)
        end
      end

      def _xhtml(*args, &block)
        if env['HTTP_ACCEPT'] and not env['HTTP_ACCEPT'].include? 'xhtml'
          return _html(*args, &block)
        end

        if block
          Wunderbar::Template::Xhtml.evaluate('_xhtml', self) do
            _xhtml(*args) { instance_eval &block }
          end
        else
          Wunderbar::Template::Xhtml.evaluate('_xhtml', self, *args)
        end
      end

      def _json(*args, &block)
        Wunderbar::Template::Json.evaluate('_json', self, *args, &block)
      end

      def _text(*args, &block)
        Wunderbar::Template::Text.evaluate('_text', self, *args, &block)
      end
    end

  else

    # allow the REQUEST_METHOD to be set for command line invocations
    ENV['REQUEST_METHOD'] ||= 'POST' if ARGV.delete('--post')
    ENV['REQUEST_METHOD'] ||= 'GET'  if ARGV.delete('--get')

    cgi.instance_variable_set '@env', ENV
    class << cgi
      attr_accessor :env

      # quick access to request_uri
      def SELF 
        env['REQUEST_URI']
      end

      def SELF?
        if SELF.include? '?'
          SELF
        else
          SELF + "?" # avoids spoiling the cache
        end
      end

      # was this invoked via HTTP POST?
      def post?
        env['REQUEST_METHOD'].to_s.upcase == 'POST'
      end
    end

    # get arguments if CGI couldn't find any... 
    cgi.params.merge!(CGI.parse(ARGV.join('&'))) if cgi.params.empty?

    require 'etc'
    $USER = ENV['REMOTE_USER'] ||= ENV['USER'] || Etc.getlogin
    if $USER.nil?
      if RUBY_PLATFORM =~ /darwin/i
        $USER = `dscl . -search /Users UniqueID #{Process.uid}`.split.first
      elsif RUBY_PLATFORM =~ /linux/i
        $USER = `getent passwd #{Process.uid}`.split(':').first
      end

      ENV['USER'] ||= $USER
    end

    ENV['HOME'] ||= Dir.home($USER) rescue nil
    ENV['HOME'] = ENV['DOCUMENT_ROOT'] if not File.exist? ENV['HOME'].to_s

    # CGI or command line
    Wunderbar::CGI.call(cgi)
  end
end
