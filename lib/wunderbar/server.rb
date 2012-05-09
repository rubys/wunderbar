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
  port = $1.to_i
  ENV['SERVER_PORT'] = port.to_s

  # Evaluate optional data from the script (after __END__)
  eval Wunderbar.data if Object.const_defined? :DATA

  # Allow optional environment override
  environment = ARGV.find {|arg| arg =~ /--environment=(.*)/}
  ENV['RACK_ENV'] = environment if environment and ARGV.delete(environment)

  at_exit do
    # start the server
    require 'rack'
    require 'wunderbar/rack'
    Rack::Server.start :app => Wunderbar::RackApp.new, :Port => port,
      :environment => (ENV['RACK_ENV'] || 'development')
  end

elsif defined? Sinatra

  require 'wunderbar/sinatra'

elsif defined? ActionView::Template

  require 'wunderbar/rails'

else

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

  $HOME = ENV['HOME']
  $HOME ||= Dir.home($USER) rescue nil
  $HOME ||= File.expand_path("~#{$USER}") rescue nil
  $HOME = ENV['DOCUMENT_ROOT'] if not $HOME or not File.exist? $HOME
  ENV['HOME'] = $HOME

  at_exit do
    if Wunderbar.queue.length > 0
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

        # split headers and content when run from the command line
        if not ENV['REQUEST_METHOD']
          def out(headers, &block)
            if ARGV.delete('--head')
              STDOUT.puts header(headers)
            elsif not ARGV.delete('--nohead')
              STDERR.puts header(headers)
            end

            STDOUT.puts block.call
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
