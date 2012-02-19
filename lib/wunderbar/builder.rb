# add indented_text!, indented_data!, system, and post? methods to builder
module Wunderbar
  class XmlMarkup < Builder::XmlMarkup
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

    # execute a system command, echoing stdin, stdout, and stderr
    def system(command, opts={})
      ::Kernel.require 'open3'
      tag  = opts[:tag]  || 'pre'
      output_class = opts[:class] || {}
      stdin  = output_class[:stdin]  || '_stdin'
      stdout = output_class[:stdout] || '_stdout'
      stderr = output_class[:stderr] || '_stderr'

      tag! tag, command, :class=>stdin unless opts[:echo] == false

      ::Kernel.require 'thread'
      semaphore = ::Mutex.new
      ::Open3.popen3(command) do |pin, pout, perr|
        [
          ::Thread.new do
            until pout.eof?
              out_line = pout.readline.chomp
              semaphore.synchronize { tag! tag, out_line, :class=>stdout }
            end
          end,

          ::Thread.new do
            until perr.eof?
              err_line = perr.readline.chomp
              semaphore.synchronize { tag! tag, err_line, :class=>stderr }
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

    # was this invoked via HTTP POST?
    def post?
      $HTTP_POST
    end
  end
end
