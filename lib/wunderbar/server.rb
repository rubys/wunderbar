# http://rack.rubyforge.org/doc/classes/Rack/Request.html
# http://rubydoc.info/gems/sinatra/Sinatra/Application
# http://www.ruby-doc.org/stdlib-1.9.3/libdoc/cgi/rdoc/CGI.html#public-class-method-details

module Wunderbar

  CALLERS_TO_IGNORE = [
    %r{/(wunderbar|webrick)/},
    %r{<internal:},
    %r{/gems/.*/lib/(builder|rack|sinatra|tilt)/}
  ]

end

port = ARGV.find {|arg| arg =~ /--port=(.*)/}
if port and ARGV.delete(port)
  ENV['SERVER_PORT'] = port.split('=').last

  # Evaluate optional data from the script (after __END__)
  eval Wunderbar.data if Object.const_defined? :DATA

  # Allow optional environment override
  environment = ARGV.find {|arg| arg =~ /--environment=(.*)/}
  if environment and ARGV.delete(environment)
    ENV['RACK_ENV'] = environment.split('=').last
  end

  at_exit do
    # start the server
    require 'wunderbar/rack'

    # whenever reloading adds to the queue, cull old entries
    class QueueCleanup
      def initialize(app)
        @app = app
        @queue = []
      end

      def call(env)
        if Wunderbar.queue != @queue
          @queue.each {|item| Wunderbar.queue.delete(item)}
          @queue = Wunderbar.queue.dup
        end
        @app.call(env)
      end
    end

    # avoid Ruby 1.9.3 bug if var names match those used to extract from ARGV
    app_port = ENV['SERVER_PORT'].to_i
    app_env = (ENV['RACK_ENV'] || 'development')

    app = Wunderbar::RackApp.new
    app = QueueCleanup.new(app)
    app = Rack::Reloader.new(app, 0) if app_env == 'development'

    Rack::Handler.default.run app, environment: app_env, Port: app_port
  end

elsif defined? Sinatra

  require 'wunderbar/sinatra'

elsif defined? ActionView::Template

  require 'wunderbar/rails'

elsif defined? Rack

  require 'wunderbar/rack'

else

  require 'etc'
  user = Etc.getpwuid.name

  $USER = ENV['REMOTE_USER'] ||= ENV['USER'] || user
  if $USER.nil?
    if RUBY_PLATFORM =~ /darwin/i
      user = $USER = `dscl . -search /Users UniqueID #{Process.uid}`.split.first
    elsif RUBY_PLATFORM =~ /linux/i
      user = $USER = `getent passwd #{Process.uid}`.split(':').first
    end

    ENV['USER'] ||= $USER
  end

  $USER = ENV['HTTP_USER'] if $USER == 'vagrant' and ENV['HTTP_USER']

  if ENV['HTTP_AUTHORIZATION']
    # RewriteEngine on
    # RewriteRule ^.*$ - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    begin
      require 'base64'
      $PASSWORD = Base64.decode64(ENV['HTTP_AUTHORIZATION'] \
        [/^Basic ([A-Za-z0-9+\/=]+)$/,1])[/^#{$USER}:(.*)/,1]
    rescue
    end
  end

  $HOME = ENV['HOME']
  $HOME = nil if $HOME == '/var/empty' or $HOME == ENV['DOCUMENT_ROOT']
  if $HOME.nil? and $USER == user
    $HOME ||= Dir.home($USER) rescue nil
    $HOME ||= File.expand_path("~#{$USER}") rescue nil
  end
  $HOME = ENV['DOCUMENT_ROOT'] if $HOME.nil? or not File.exist? $HOME
  ENV['HOME'] = $HOME

  at_exit do
    if Wunderbar.queue.length > 0
      # Only prompt if explicitly asked for
      ARGV.push '' if ARGV.empty?
      ARGV.delete('--prompt') or ARGV.delete('--offline')

      payload = nil
      if env['CONTENT_TYPE'] =~ %r{^application/json(;.*)?$}
        # read payload before CGI.new eats $stdin
        payload = JSON.parse($stdin.read) rescue nil
      end

      cgi = CGI.new

      cgi.params.merge!(payload) if payload rescue nil
      payload = nil

      cgi.instance_variable_set '@env', ENV
      class << cgi
        attr_accessor :env

        # was this invoked via HTTP POST?
        %w(delete get head options post put trace).each do |http_method|
          define_method "#{http_method}?" do
            env['REQUEST_METHOD'].to_s.downcase == http_method
          end
        end

        # return only headers or content when run from the command line
        if not ENV['REQUEST_METHOD']
          def out(headers, &block)
            if ARGV.delete('--head')
              print "HTTP/1.1 #{headers.delete('status') || '200 OK'}\r\n"
              require 'time'
              headers['Date'] = Time.now.utc.rfc2822.sub(/-0000$/, 'GMT')
              headers['Content-Length'] = block.call.bytesize
              print header(headers)
            else
              print block.call
            end
          end
        end
      end

      # get arguments if CGI couldn't find any... 
      cgi.params.merge!(CGI.parse(ARGV.join('&'))) if cgi.params.empty?

      # allow the REQUEST_METHOD to be set for command line invocations
      ENV['REQUEST_METHOD'] ||= 'POST' if ARGV.delete('--post')
      ENV['REQUEST_METHOD'] ||= 'GET'  if ARGV.delete('--get')

      # CGI or command line
      if Wunderbar.safe? and $SAFE==0
        Proc.new { $SAFE=1; Wunderbar::CGI.call(cgi) }.call
      else
        Wunderbar::CGI.call(cgi)
      end
    end
  end
end
