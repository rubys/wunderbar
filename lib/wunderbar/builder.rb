module Builder
  class XmlMarkup < XmlBase
    unless method_defined? :indented_text!
      def indented_text!(text)
        indented_data!(text) {|data| text! data}
      end
    end

    unless method_defined? :indented_data!
      def indented_data!(data, &block)
        return if data.strip.length == 0

        if @indent > 0
          data.sub! /\n\s*\Z/, ''
          data.sub! /\A\s*\n/, ''

          unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1

          before  = ::Regexp.new('^'.ljust(unindent))
          after   =  " " * (@level * @indent)
          data.gsub! before, after
        end

        if block
          block.call(data)
        else
          self << data
        end

        _newline unless data =~ /\n\Z/
      end
    end

    unless method_defined? :disable_indentation!
      def disable_indendation!(&block)
        indent, level = @indent, @level
        @indent = @level = 0
        text! " "*indent*level
        block.call
      ensure
        text! "\n"
        @indent, @level = indent, level
      end
    end
  end
end

module Wunderbar
  class XmlMarkup
    def initialize(*args)
      @x = Builder::XmlMarkup.new(*args)
    end

    # forward to either Wunderbar or XmlMarkup
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        Wunderbar.send method, *args, &block
      elsif Builder::XmlMarkup.public_instance_methods.include? method
        @x.__send__ method, *args, &block
      elsif Builder::XmlMarkup.public_instance_methods.include? method.to_s
        @x.__send__ method, *args, &block
      else
        super
      end
    end

    # avoid method_missing overhead for the most common case
    def tag!(*args, &block)
      @x.__send__ :tag!, *args, &block
    end

    # execute a system command, echoing stdin, stdout, and stderr
    def system(command, opts={})
      ::Kernel.require 'open3'
      tag  = opts[:tag]  || 'pre'
      output_class = opts[:class] || {}
      stdin  = output_class[:stdin]  || '_stdin'
      stdout = output_class[:stdout] || '_stdout'
      stderr = output_class[:stderr] || '_stderr'

      @x.tag! tag, command, :class=>stdin unless opts[:echo] == false

      ::Kernel.require 'thread'
      semaphore = ::Mutex.new
      ::Open3.popen3(command) do |pin, pout, perr|
        [
          ::Thread.new do
            until pout.eof?
              out_line = pout.readline.chomp
              semaphore.synchronize { @x.tag! tag, out_line, :class=>stdout }
            end
          end,

          ::Thread.new do
            until perr.eof?
              err_line = perr.readline.chomp
              semaphore.synchronize { @x.tag! tag, err_line, :class=>stderr }
            end
          end,

          ::Thread.new do
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
      declare!(*args)
    end

    # comment
    def comment(*args)
      comment! *args
    end

    # was this invoked via HTTP POST?
    def post?
      $HTTP_POST
    end
  end
end
