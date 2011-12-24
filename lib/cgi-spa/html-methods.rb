# smart style, knows that the content is indented text/data
def $x.style!(text)
  text.slice! /^\n/
  text.slice! /[ ]+\z/
  $x.style :type => "text/css" do
    if $XHTML
      indented_text! text
    else
      indented_data! text
    end
  end
end

# smart script, knows that the content is indented text/data
def $x.script!(text)
  text.slice! /^\n/
  text.slice! /[ ]+\z/
  $x.script :lang => "text/javascript" do
    if $XHTML
      indented_text! text
    else
      indented_data! text
    end
  end
end

# execute a system command, echoing stdin, stdout, and stderr
def $x.system!(command, opts={})
  require 'open3'
  output_class = opts[:class] || {}
  stdin  = output_class[:stdin]  || 'stdin'
  stdout = output_class[:stdout] || 'stdout'
  stderr = output_class[:stderr] || 'stderr'

  $x.pre command, :class=>stdin unless opts[:echo] == false

  require 'thread'
  semaphore = Mutex.new
  Open3.popen3(command) do |pin, pout, perr|
    [
      Thread.new do
        until pout.eof?
          out_line = pout.readline.chomp
          semaphore.synchronize { $x.pre out_line, :class=>stdout }
        end
      end,

      Thread.new do
        until perr.eof?
          err_line = perr.readline.chomp
          semaphore.synchronize { $x.pre err_line, :class=>stderr }
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

def $x.body? args={}
  traceback_class = args.delete('traceback_class')
  traceback_style = args.delete('traceback_style')
  traceback_style ||= 'background-color:#ff0; margin: 1em 0; padding: 1em; ' +
    'border: 4px solid red; border-radius: 1em'
  $x.body(args) do
    begin
      yield
    rescue Exception => exception
      text = exception.inspect
      exception.backtrace.each {|frame| text += "\n  #{frame}"}

      if traceback_class
        $x.pre text, :class=>traceback_class
      else
        $x.pre text, :style=>traceback_style
      end
    end
  end
end
