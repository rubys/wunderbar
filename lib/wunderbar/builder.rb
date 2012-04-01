module Wunderbar
  # XmlMarkup handles indentation of elements beautifully, this class extends
  # that support to text, data, and spacing between elements
  class SpacedMarkup < Builder::XmlMarkup
    def indented_text!(text)
      indented_data!(text) {|data| text! data}
    end

    def indented_data!(data, &block)
      return if data.strip.length == 0

      if @indent > 0
        data.sub! /\n\s*\Z/, ''
        data.sub! /\A\s*\n/, ''

        unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1

        before  = ::Regexp.new('^'.ljust(unindent))
        after   =  " " * (@level * @indent)
        data.gsub! before, after

        _newline if @pending_newline and not @first_tag
        @pending_newline = @pending_margin
        @first_tag = @pending_margin = false
      end

      if block
        block.call(data)
      else
        self << data
      end

      _newline unless data =~ /\n\Z/
    end

    def disable_indendation!(&block)
      indent, level, pending_newline, pending_margin = 
        indentation_state! [0, 0, @pending_newline, @pending_margin]
      text! " "*indent*level
      block.call
    ensure
      indentation_state! [indent, level, pending_newline, pending_margin]
    end

    def indentation_state! new_state=nil
      result = [@indent, @level, @pending_newline, @pending_margin]
      if new_state
        text! "\n" if @indent == 0 and new_state.first > 0
        @indent, @level, @pending_newline, @pending_margin = new_state
      end
      result
    end

    def margin!
      _newline unless @first_tag
      @pending_newline = false
      @pending_margin = true
    end

    def _nested_structures(*args)
      pending_newline = @pending_newline
      @pending_newline = false
      @first_tag = true
      super
      @first_tag = @pending_margin = false
      @pending_newline = pending_newline
    end

    def tag!(sym, *args, &block)
      _newline if @pending_newline
      @pending_newline = @pending_margin
      @first_tag = @pending_margin = false
      super
    end
  end

  class XmlMarkup
    def initialize(*args)
      @x = SpacedMarkup.new(*args)
    end

    # forward to either Wunderbar or XmlMarkup
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        Wunderbar.send method, *args, &block
      elsif SpacedMarkup.public_instance_methods.include? method
        @x.__send__ method, *args, &block
      elsif SpacedMarkup.public_instance_methods.include? method.to_s
        @x.__send__ method, *args, &block
      else
        super
      end
    end

    # avoid method_missing overhead for the most common case
    def tag!(sym, *args, &block)
      if !block and (args.empty? or args == [''])
        CssProxy.new(@x, @x.target!, sym, args)
      else
        @x.tag! sym, *args, &block
      end
    end

    # execute a system command, echoing stdin, stdout, and stderr
    def system(command, opts={})
      if command.respond_to? :join
        begin
          # if available, use escape as it does prettier quoting
          require 'escape'
          command = Escape.shell_command(command)
        rescue LoadError
          # std-lib function that gets the job done
          require 'shellwords'
          command = Shellwords.join(command)
        end
      end

      require 'open3'
      tag  = opts[:tag]  || 'pre'
      output_class = opts[:class] || {}
      stdin  = output_class[:stdin]  || '_stdin'
      stdout = output_class[:stdout] || '_stdout'
      stderr = output_class[:stderr] || '_stderr'

      @x.tag! tag, command, :class=>stdin unless opts[:echo] == false

      require 'thread'
      semaphore = Mutex.new
      Open3.popen3(command) do |pin, pout, perr|
        [
          Thread.new do
            until pout.eof?
              out_line = pout.readline.chomp
              semaphore.synchronize { @x.tag! tag, out_line, :class=>stdout }
            end
          end,

          Thread.new do
            until perr.eof?
              err_line = perr.readline.chomp
              semaphore.synchronize { @x.tag! tag, err_line, :class=>stderr }
            end
          end,

          Thread.new do
            if opts[:stdin].respond_to? :read
              require 'fileutils'
              FileUtils.copy_stream opts[:stdin], pin
            elsif opts[:stdin]
              pin.write opts[:stdin].to_s
            end
            pin.close
          end
        ].each {|thread| thread.join}
      end
    end

    # declaration (DOCTYPE, etc)
    def declare(*args)
      @x.declare!(*args)
    end

    # comment
    def comment(*args)
      @x.comment! *args
    end

    # was this invoked via HTTP POST?
    def post?
      $HTTP_POST
    end
  end

  class TextBuilder
    def initialize
      require 'stringio'
      @_target = StringIO.new
    end

    def encode(params = {}, &block)
      params.each do |key,value|
        instance_variable_set "@#{key}", value.first if key =~ /^\w+$/
      end

      self.instance_eval(&block)
      @_target.string
    end

    def _(*args)
      @_target.puts *args if args.length > 0 
      self
    end

    # forward to either Wunderbar or @_target
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        return Wunderbar.send method, *args, &block
      elsif @_target.respond_to? method
        return @_target.send method, *args, &block
      else
        super
      end
    end

    def target!
      @_target.string
    end
  end

  class JsonBuilder
    def initialize
      @_target = {}
    end

    def encode(params = {}, &block)
      params.each do |key,value|
        instance_variable_set "@#{key}", value.first if key =~ /^\w+$/
      end

      self.instance_eval(&block)
      @_target
    end

    # forward to either Wunderbar or @_target
    def method_missing(method, *args, &block)

      if method.to_s =~ /^_(\w*)$/
        name = $1
      elsif Wunderbar.respond_to? method
        return Wunderbar.send method, *args, &block
      elsif @_target.respond_to? method
        return @_target.send method, *args, &block
      else
        super
      end

      if args.length == 0
        return self unless block
        result = JsonBuilder.new.encode(&block)
      elsif args.length == 1
        result = args.first

        if block
          if Symbol === result or String === result
            result = {result.to_s => JsonBuilder.new.encode(&block)}
          else
            result = result.map {|n| @_target = {}; block.call(n); @_target} 
          end
        end
      elsif block
        ::Kernel::raise ::ArgumentError, 
          "can't mix multiple arguments with a block"
      else
        object = args.shift

        if not Enumerable === object or String === object or Struct === object
          result = {}
          args.each {|arg| result[arg.to_s] = object.send arg}
        else
          result = object.map do |item|
            args.inject({}) {|hash, arg| hash[arg.to_s] = item.send arg; hash}
          end
        end
      end

      if name != ''
        unless Hash === @_target or @_target.empty?
          ::Kernel::raise ::ArgumentError, "mixed array and hash calls"
        end

        @_target[name.to_s] = result
      elsif args.length == 0 or (args.length == 1 and not block)
        @_target = [] if @_target == {}

        if Hash === @_target 
          ::Kernel::raise ::ArgumentError, "mixed hash and array calls"
        end

        @_target << result
      else
        @_target = result
      end

      self
    end

    def _!(object)
      @_target = object
    end

    def target!
      begin
        JSON.pretty_generate(@_target)+ "\n"
      rescue
        @_target.to_json + "\n"
      end
    end
  end
end
