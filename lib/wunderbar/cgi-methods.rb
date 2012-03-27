module Wunderbar

  module CGI

    # produce json
    def self.json(&block)
      return unless $XHR_JSON
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
      if $XHR_JSON
        Kernel.print "Status: 404 Not Found\r\n" unless output
        out? 'type' => 'application/json', 'Cache-Control' => 'no-cache' do
          begin
            JSON.pretty_generate(output)+ "\n"
          rescue
            output.to_json + "\n"
          end
        end
      end
    end

    # produce json and quit
    def self.json! &block
      return unless $XHR_JSON
      json(&block)
      Process.exit
    end

    # produce text
    def self.text &block
      require 'stringio'
      return unless $TEXT
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
      if $TEXT
        Kernel.print "Status: 404 Not Found\r\n" if buffer.size == 0
        out? 'type' => 'text/plain', 'Cache-Control' => 'no-cache' do
          buffer.string
        end
      end
    end

    # produce text and quit
    def self.text! &block
      return unless $TEXT
      text(&block)
      Process.exit
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
      return if $XHR_JSON or $TEXT
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

    # produce html and quit
    def self.html! *args, &block
      return if $XHR_JSON or $TEXT
      html(*args, &block)
      Process.exit
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

  # canonical interface
  def self.html(*args, &block)
    $XHTML = false unless ARGV.delete('--xhtml')
    CGI.html!(*args, &block)
  end

  def self.xhtml(*args, &block)
    $XHTML = false if ARGV.delete('--html')
    CGI.html!(*args, &block)
  end

  def self.json(*args, &block)
    CGI.json!(*args, &block)
  end

  def self.text(*args, &block)
    CGI.text!(*args, &block)
  end
end
