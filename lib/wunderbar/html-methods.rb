# Wrapper class that understands HTML
class HtmlMarkup
  VOID = %w(
    area base br col command embed hr img input keygen
    link meta param source track wbr
  )

  def initialize(*args, &block)
    @x = Wunderbar::XmlMarkup.new :indent => 2
  end

  def html(*args, &block)
    @x.tag! :html, *args do 
      $param.each do |key,value| 
        instance_variable_set "@#{key}", value.first if key =~ /^\w+$/
      end
      instance_exec(@x, &block)
    end
  end

  def method_missing(name, *args, &block)
    if name.to_s =~ /^_(\w+)(!|\?|)$/
      name, flag = $1, $2
    else
      error = NameError.new "undefined local variable or method `#{name}'", name
      error.set_backtrace caller
      raise error
    end

    if name.sub!(/_$/,'')
      @x.margin!
    end

    if flag != '!'
      if %w(script style).include?(name)
        if String === args.first and not block
          text = args.shift
          if $XHTML
            block = Proc.new {@x.indented_text! text}
          else
            block = Proc.new {@x.indented_data! text}
          end
        end

        args << {} if args.length == 0
        if Hash === args.last
          args.last[:lang] ||= 'text/javascript' if name == 'script'
          args.last[:type] ||= 'text/css' if name == 'style'
        end
      end

      # ensure that non-void elements are explicitly closed
      if args.length == 0 or (args.length == 1 and Hash === args.first)
        args.unshift '' if not VOID.include?(name) and not block
      end

      # remove attributes with nil values
      args.last.delete_if {|key, value| value == nil} if Hash === args.last
    end

    if flag == '!'
      @x.disable_indendation! do
        @x.tag! name, *args, &block
      end
    elsif flag == '?'
      # capture exceptions, produce filtered tracebacks
      options = (Hash === args.last)? args.last : {}
      traceback_class = options.delete(:traceback_class)
      traceback_style = options.delete(:traceback_style)
      traceback_style ||= 'background-color:#ff0; margin: 1em 0; ' +
        'padding: 1em; border: 4px solid red; border-radius: 1em'
      @x.tag!(name, *args) do
        begin
          block.call
        rescue ::Exception => exception
          text = exception.inspect
          Wunderbar.warn text
          exception.backtrace.each do |frame| 
            next if frame =~ %r{/wunderbar/}
            next if frame =~ %r{/gems/.*/builder/}
            Wunderbar.warn "  #{frame}"
            text += "\n  #{frame}"
          end
    
          if traceback_class
            @x.tag! :pre, text, :class=>traceback_class
          else
            @x.tag! :pre, text, :style=>traceback_style
          end
        end
      end
    else
      @x.tag! name, *args, &block
    end
  end

  def _head(*args, &block)
    @x.tag!('head', *args) do
      @x.tag! :meta, :charset => 'utf-8' unless $XHTML
      block.call if block
    end
  end

  def _svg(*args, &block)
    args << {} if args.empty?
    args.first['xmlns'] = 'http://www.w3.org/2000/svg' if Hash === args.first
    @x.tag! :svg, *args, &block
  end

  def _math(*args, &block)
    args << {} if args.empty?
    if Hash === args.first
      args.first['xmlns'] = 'http://www.w3.org/1998/Math/MathML'
    end
    @x.tag! :math, *args, &block
  end

  def _(text=nil)
    @x.indented_text! text if text
    @x
  end

  def _!(text=nil)
    @x.text! text if text
    @x
  end

  def _coffeescript(text)
    require 'coffee-script'
    _script CoffeeScript.compile(text)
  rescue LoadError
    _script text, :lang => 'text/coffeescript'
  end

  def target!
    @x.target!
  end
end
