require 'digest/md5'

module Wunderbar
  class CGI

    # produce json
    def json(scope, &block)
      headers = { 'type' => 'application/json', 'Cache-Control' => 'no-cache' }
      builder = JsonBuilder.new(scope)
      output = builder.encode(&block)
      headers['status'] =  "404 Not Found" if output == {}
    rescue Exception => exception
      headers['status'] =  "500 Internal Server Error"
      builder._! Hash.new
      builder._exception exception
    ensure
      out?(scope, headers) { builder.target! }
    end

    # produce text
    def text(scope, &block)
      headers = {'type' => 'text/plain', 'charset' => 'UTF-8'}
      builder = TextBuilder.new(scope)
      output = builder.encode(&block)
      headers['status'] =  "404 Not Found" if output == ''
    rescue Exception => exception
      headers['status'] =  "500 Internal Server Error"
      builder._exception exception
    ensure
      out?(scope, headers) { builder.target! }
    end

    # Conditionally provide output, based on ETAG
    def out?(scope, headers, &block)
      content = block.call
      etag = Digest::MD5.hexdigest(content)

      if scope.env['HTTP_IF_NONE_MATCH'] == etag.inspect
        headers['Date'] = ::CGI.rfc1123_date(Time.now)
        scope.out headers.merge('status' => '304 Not Modified') do
          ''
        end
      else
        scope.out headers.merge('Etag' => etag.inspect) do
          content
        end
      end
    rescue Exception => exception
      Wunderbar.fatal exception.inspect
    end

    def html2pdf(input=nil, &block)
      require 'thread'
      require 'open3'
      require 'stringio'

      display=":#{rand(999)+1}"
      pid = fork do
        # close open files
        STDIN.reopen '/dev/null'
        STDOUT.reopen '/dev/null', 'a'
        STDERR.reopen STDOUT

        Process.setsid
        Wunderbar.error Process.exec("Xvfb #{display}")
        Process.exit
      end
      Process.detach(pid)

      ENV['DISPLAY']=display
      input ||= block.call
      output = StringIO.new

      Open3.popen3('wkhtmltopdf - -') do |pin, pout, perr|
        [
          Thread.new { pin.write input; pin.close },
          Thread.new { IO.copy_stream(pout, output) },
          Thread.new { perr.readpartial(4096) until perr.eof? }
        ].map(&:join)
      end

      output.string
    ensure
      Process.kill 'INT', pid rescue nil
    end

    # produce html/xhtml
    def html(scope, *args, &block)
      headers = { 'type' => 'text/html', 'charset' => 'UTF-8' }
      headers['type'] = 'application/xhtml+xml' if @xhtml

      x = HtmlMarkup.new(scope)

      begin
        if @pdf
          x._.pdf = true if @pdf
          headers = { 'type' => 'application/pdf' }
          output = html2pdf {x.html *args, &block}
        else
          output = x.html *args, &block
        end
      rescue ::Exception => exception
        headers['status'] =  "500 Internal Server Error"
        x.clear!
        output = x.html(*args) do
          _h1 'Internal Server Error'
          _exception exception
        end
      end

      out?(scope, headers) { output }
    end

    def self.call(scope)
      new.call(scope)
    end

    def call(scope)
      # asset support for Rack
      request = (scope.respond_to? :request) ? scope.request : nil
      if request and request.path =~ %r{/assets/\w[-.\w]+}
        path = ('.' + scope.request.path).untaint
        headers = {'type' => 'text/plain'}
        headers['type'] = 'application/javascript' if path =~ /\.js$/
        out?(scope, headers) { File.read path if File.exist? path }
        return
      end

      env = scope.env
      accept    = env['HTTP_ACCEPT'].to_s
      path_info = env['PATH_INFO'].to_s

      # implied request types
      text = Wunderbar::Options::TEXT || (accept =~ /plain/ && accept !~ /html/)
      xhr_json = Wunderbar::Options::XHR_JSON || (accept =~ /json/)
      xhr_json ||= !text && env['HTTP_X_REQUESTED_WITH'].to_s=='XMLHttpRequest'
      @xhtml = (accept =~ /xhtml/ or accept == '')
      @pdf   = (accept =~ /pdf/)

      # parse json arguments
      if xhr_json and request and request.respond_to? :body
        if env['CONTENT_TYPE'] =~ %r{^application/json(;.*)?$}
          scope.params.merge! JSON.parse(scope.request.body.read)
        end
      end

      # overrides via the command line
      xhtml_override = ARGV.include?('--xhtml')
      html_override  = ARGV.include?('--html')
      @pdf           ||= ARGV.include?('--pdf')

      # overrides via the uri query parameter
      # xhr_json       ||= (path_info.end_with? '.json')
      text           ||= (path_info.end_with? '.text')
      @pdf           ||= (path_info.end_with? '.pdf')
      xhtml_override ||= (path_info.end_with? '.xhtml')
      html_override  ||= (path_info.end_with? '.html')

      # disable conneg if only one handler is provided
      if Wunderbar.queue.length == 1
        type = Wunderbar.queue.first.first
        xhr_json = (type == :json)
        text     = (type == :text)
      end

      Wunderbar.queue.each do |type, args, block|
        case type
        when :html, :xhtml
          unless xhr_json or text
            if type == :html
              @xhtml = false unless xhtml_override
            else
              @xhtml = false if html_override
            end

            self.html(scope, *args, &block)
            return
          end
        when :json
          if xhr_json
            self.json(scope, *args, &block)
            return
          end
        when :text
          if text
            self.text(scope, *args, &block)
            return
          end
        when Proc
          unless xhr_json or text
            instance_exec scope, args, block, &type
            return
          end
        end
      end
    end

    # map Ruby CGI headers to Rack headers
    def self.headers(headers)
      result = headers.dup
      type = result.delete('type') || 'text/html'
      charset = result.delete('charset')
      type = "#{type}; charset=#{charset}" if charset
      result['Content-Type'] ||= type
      result
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

  def self.queue
    @queue
  end
end
