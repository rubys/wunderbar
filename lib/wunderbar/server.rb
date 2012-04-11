# http://rack.rubyforge.org/doc/classes/Rack/Request.html
# http://rubydoc.info/gems/sinatra/Sinatra/Application
# http://www.ruby-doc.org/stdlib-1.9.3/libdoc/cgi/rdoc/CGI.html#public-class-method-details

at_exit do
  port = ARGV.find {|arg| arg =~ /--port=(.*)/}
  if port and ARGV.delete(port)
    port = $1.to_i

    # Evaluate optional data from the script (after __END__)
    eval Wunderbar.data if Object.const_defined? :DATA

    # Allow optional environment override
    environment = ARGV.find {|arg| arg =~ /--environment=(.*)/}
    ENV['RACK_ENV'] = environment if environment and ARGV.delete(environment)

    # start the server
    require 'rack'
    require 'wunderbar/rack'
    Rack::Server.start :app => Wunderbar::RackApp.new, :Port => port,
      :environment => (ENV['RACK_ENV'] || 'development')

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

  elsif Wunderbar.queue.length > 0

    # allow the REQUEST_METHOD to be set for command line invocations
    ENV['REQUEST_METHOD'] ||= 'POST' if ARGV.delete('--post')
    ENV['REQUEST_METHOD'] ||= 'GET'  if ARGV.delete('--get')

    # Only prompt if explicitly asked for
    ARGV.push '' if ARGV.empty?
    ARGV.delete('--prompt') or ARGV.delete('--offline')

    cgi = CGI.new
    cgi.instance_variable_set '@env', ENV
    class << cgi
      attr_accessor :env

      # was this invoked via HTTP POST?
      %w(delete get head options post put trace).each do |http_method|
        define_method "#{http_method}?" do
          env['REQUEST_METHOD'].to_s.downcase == http_method
        end
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
