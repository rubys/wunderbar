module Wunderbar

  module CGI

    # produce json
    def self.json(&block)
      builder = JsonBuilder.new
      output = builder.encode($params, &block)
      Kernel.print "Status: 404 Not Found\r\n" if output == {}
    rescue Exception => exception
      Kernel.print "Status: 500 Internal Error\r\n"
      Wunderbar.error exception.inspect
      backtrace = []
      exception.backtrace.each do |frame| 
        next if frame =~ %r{/wunderbar/}
        next if frame =~ %r{/gems/.*/builder/}
        Wunderbar.warn "  #{frame}"
        backtrace << frame 
      end
      builder = JsonBuilder.new
      builder._exception exception.inspect
      builder._backtrace backtrace
    ensure
      out? 'type' => 'application/json', 'Cache-Control' => 'no-cache' do
        builder.target!
      end
    end

    # produce text
    def self.text &block
      builder = TextBuilder.new
      output = builder.encode($params, &block)
      Kernel.print "Status: 404 Not Found\r\n" if output == ''
    rescue Exception => exception
      Wunderbar.error exception.inspect
      Kernel.print "Status: 500 Internal Error\r\n"
      builder.puts unless builder.size == 0
      builder.puts exception.inspect
      exception.backtrace.each do |frame| 
        next if frame =~ %r{/wunderbar/}
        next if frame =~ %r{/gems/.*/builder/}
        Wunderbar.warn "  #{frame}"
        builder.puts "  #{frame}"
      end
    ensure
      out? 'type' => 'text/plain', 'Cache-Control' => 'no-cache' do
        builder.target!
      end
    end

    # Conditionally provide output, based on ETAG
    def self.out?(headers, &block)
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
    rescue
    end

    # produce html/xhtml
    def self.html(*args, &block)
      if Hash === args.first and args.first[:xmlns] == 'http://www.w3.org/1999/xhtml'
        mimetype = 'application/xhtml+xml'
      else
        mimetype = 'text/html'
      end

      x = HtmlMarkup.new
      x._! "\xEF\xBB\xBF"
      x._.declare :DOCTYPE, :html

      begin
        output = x.html *args, &block
      rescue ::Exception => exception
        Kernel.print "Status: 500 Internal Error\r\n"
        x.clear!
        x._! "\xEF\xBB\xBF"
        x._.declare :DOCTYPE, :html
        output = x.html(*args) do
          _head do
            _title 'Internal Error'
          end
          _body do
            _h1 'Internal Error'
            text = exception.inspect
            Wunderbar.error text
            exception.backtrace.each do |frame| 
              next if frame =~ %r{/wunderbar/}
              next if frame =~ %r{/gems/.*/builder/}
              Wunderbar.warn "  #{frame}"
              text += "\n  #{frame}"
            end
    
            _pre text
          end
        end
      end

      out? 'type' => mimetype, 'charset' => 'UTF-8' do
        output
      end
    end
  end

  @queue = []

  # canonical interface
  def self.html(*args, &block)
    @queue << [:html, args, block]
  end

  def self.xhtml(*args, &block)
    @queue << [:xhtml, args, block]
  end

  def self.json(*args, &block)
    @queue << [:json, args, block]
  end

  def self.text(*args, &block)
    @queue << [:text, args, block]
  end

  def self.call(env)
    require 'etc'
    $USER = ENV['REMOTE_USER'] ||= ENV['USER'] || Etc.getlogin

    accept         = $env.HTTP_ACCEPT.to_s
    request_uri    = $env.REQUEST_URI.to_s

    # implied request types
    xhr_json = Wunderbar::Options::XHR_JSON  || (accept =~ /json/)
    text = Wunderbar::Options::TEXT || (accept =~ /plain/ and accept !~ /html/)
    xhtml = (accept =~ /xhtml/ or accept == '')

    # overrides via the uri query parameter
    xhr_json  ||= (request_uri =~ /\?json$/)
    text       ||= (request_uri =~ /\?text$/)

    # overrides via the command line
    xhtml_override = ARGV.include?('--xhtml')
    html_override  = ARGV.include?('--html')

    @queue.each do |type, args, block|
      case type
      when :html, :xhtml
        unless xhr_json or text
          if type == :html
            xhtml = false unless xhtml_override
          else
            xhtml = false if html_override
          end

          if xhtml
            args << {} if args.empty?
            if Hash === args.first
              args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml'
            end
          end

          CGI.html(*args, &block)
          return
        end
      when :json
        if xhr_json
          CGI.json(*args, &block)
          return
        end
      when :text
        if text
          CGI.text(*args, &block)
          return
        end
      end
    end
  end

  def self.clear!
    @queue.clear
  end
end
