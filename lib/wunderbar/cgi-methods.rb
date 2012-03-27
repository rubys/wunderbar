module Wunderbar

  module CGI

    # produce json
    def self.json(&block)
      $param.each do |key,value| 
        instance_variable_set "@#{key}", value.first if key =~ /^\w+$/
      end
      output = instance_eval(&block)
    rescue Exception => exception
      Kernel.print "Status: 500 Internal Error\r\n"
      output = {
        :exception => exception.inspect,
        :backtrace => exception.backtrace
      }
    ensure
      Kernel.print "Status: 404 Not Found\r\n" unless output
      out? 'type' => 'application/json', 'Cache-Control' => 'no-cache' do
        begin
          JSON.pretty_generate(output)+ "\n"
        rescue
          output.to_json + "\n"
        end
      end
    end

    # produce text
    def self.text &block
      require 'stringio'
      buffer = StringIO.new
      $param.each do |key,value| 
        instance_variable_set "@#{key}", value.first if key =~ /^\w+$/
      end
      buffer.instance_eval &block
    rescue Exception => exception
      Kernel.print "Status: 500 Internal Error\r\n"
      buffer << "\n" unless buffer.size == 0
      buffer << exception.inspect + "\n"
      exception.backtrace.each {|frame| buffer << "  #{frame}\n"}
    ensure
      Kernel.print "Status: 404 Not Found\r\n" if buffer.size == 0
      out? 'type' => 'text/plain', 'Cache-Control' => 'no-cache' do
        buffer.string
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
      args << {} if args.empty?
      if Hash === args.first
        args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml'
      end
      mimetype = ($XHTML ? 'application/xhtml+xml' : 'text/html')
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

    # post specific logic (doesn't produce output)
    def self.post
      yield if $HTTP_POST
    end

    # post specific content (produces output)
    def self.post! &block
      html!(&block) if $HTTP_POST
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

  def self.evaluate
    queue, @queue = @queue, []
    xhtml = ARGV.delete('--xhtml')
    html  = ARGV.delete('--html')

    queue.each do |type, args, block|
      case type
      when :html
        unless $XHR_JSON or $TEXT
          $XHTML = false unless xhtml
          CGI.html(*args, &block)
          Process.exit
        end
      when :xhtml
        unless $XHR_JSON or $TEXT
          $XHTML = false if html
          CGI.html(*args, &block)
          Process.exit
        end
      when :json
        if $XHR_JSON
          CGI.json(*args, &block)
          Process.exit
        end
      when :text
        if $TEXT
          CGI.text(*args, &block)
          Process.exit
        end
      end
    end
  end
end

at_exit do
  Wunderbar.evaluate
end
