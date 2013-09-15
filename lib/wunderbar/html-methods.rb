# Wrapper class that understands HTML
module Wunderbar
  class HtmlMarkup < BuilderBase
    VOID = %w(
      area base br col command embed hr img input keygen
      link meta param source track wbr
    )

    HTML5_BLOCK = %w(
      # https://developer.mozilla.org/en/HTML/Block-level_elements
      address article aside audio blockquote br canvas dd div dl fieldset
      figcaption figcaption figure footer form h1 h2 h3 h4 h5 h6 header hgroup
      hr noscript ol output p pre section table tfoot ul video
    )

    def initialize(scope)
      @_scope = scope
      @x = XmlMarkup.new :scope => scope, :indent => 2, :target => []
    end

    def html(*args, &block)
      # default namespace
      args << {} if args.empty?
      if Hash === args.first
        args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml'
      end
      @_width = args.first.delete(:_width) if Hash === args.first

      @x.text! "\xEF\xBB\xBF"
      @x.declare! :DOCTYPE, :html
      @x.tag! :html, *args do 
        set_variables_from_params
        instance_eval(&block)
      end

      if @_width
        self.class.reflow(@x.target!, @_width)
      end

      @x.target!.join
    end

    def _html(*args, &block)
      html(*args, &block)
    end

    def method_missing(name, *args, &block)
      if name.to_s =~ /^_(\w+)(!|\?|)$/
        name, flag = $1, $2
      elsif @_scope and @_scope.respond_to? name
        return @_scope.__send__ name, *args, &block
      elsif TOPLEVEL_BINDING.eval('local_variables').include? name
        return TOPLEVEL_BINDING.eval(name.to_s)
      else
        err = NameError.new "undefined local variable or method `#{name}'", name
        err.set_backtrace caller
        raise err
      end

      if name.sub!(/_$/,'')
        @x.margin!
        return __send__ "_#{name}", *args, &block if respond_to? "_#{name}"
      end

      if flag != '!'
        if %w(script style).include?(name)
          if String === args.first and not block
            text = args.shift
            if !text.include? '&' and !text.include? '<'
              block = Proc.new do
                @x.indented_data!(text)
              end
            elsif name == 'style'
              block = Proc.new do
                @x.indented_data!(text, "/*<![CDATA[*/", "/*]]>*/")
              end
            else
              block = Proc.new do
                @x.indented_data!(text, "//<![CDATA[", "//]]>")
              end
            end
          end

          args << {} if args.length == 0
          if Hash === args.last
            args.last[:lang] ||= 'text/javascript' if name == 'script'
            args.last[:type] ||= 'text/css' if name == 'style'
          end
        end

        # ensure that non-void elements are explicitly closed
        if not block and not VOID.include?(name)
          args[0] = '' if args.length > 1 and args.first == nil
          symbol = (args.shift if args.length > 0 and Symbol === args.first)
          if args.length == 0 or (args.length == 1 and Hash === args.first)
            args.unshift ''
          end
          args.unshift(symbol) if symbol
        end

        if String === args.first and args.first.respond_to? :html_safe?
          if args.first.html_safe? and not block and args.first =~ /[>&]/
            markup = args.shift
            block = Proc.new {_ {markup}}
          end
        end

        if Hash === args.last
          # remove attributes with nil, false values
          args.last.delete_if {|key, value| !value}

          # replace boolean 'true' attributes with the name of the attribute
          args.last.each {|key, value| args.last[key]=key if value == true}
        end
      end

      if flag == '!'
        @x.disable_indentation! do
          @x.tag! name, *args, &block
        end
      elsif flag == '?'
        # capture exceptions, produce filtered tracebacks
        @x.tag!(name, *args) do
          begin
            block.call
          rescue ::Exception => exception
            options = (Hash === args.last)? args.last : {}
            options[:log_level] = 'warn'
            _exception exception, options
          end
        end
      else
        target = @x.tag! name, *args, &block
        if block and %w(script style).include?(name)
          if %w{//]]> /*]]>*/}.include? target[-4]
            target[-4], target[-3] = target[-3], target[-4]
          end
        end
        target
      end
    end

    def _exception(*args)
      exception = args.first
      if exception.respond_to? :backtrace
        options = (Hash === args.last)? args.last : {}
        traceback_class = options.delete(:traceback_class)
        traceback_style = options.delete(:traceback_style)
        traceback_style ||= 'background-color:#ff0; margin: 1em 0; ' +
          'padding: 1em; border: 4px solid red; border-radius: 1em'

        text = exception.inspect
        log_level = options.delete(:log_level) || :error
        Wunderbar.send log_level, text
        exception.backtrace.each do |frame| 
          next if Wunderbar::CALLERS_TO_IGNORE.any? {|re| frame =~ re}
          Wunderbar.send log_level, "  #{frame}"
          text += "\n  #{frame}"
        end
   
        if traceback_class
          @x.tag! :pre, text, :class=>traceback_class
        else
          @x.tag! :pre, text, :style=>traceback_style
        end
      else
        super
      end
    end

    def _head(*args, &block)
      @x.tag!('head', *args) do
        @x.tag! :meta, :charset => 'utf-8'
        block.call if block
        instance_eval &Wunderbar::Asset.declarations
      end
    end

    def _p(*args, &block)
      if args.length >= 1 and String === args.first and args.first.include? "\n"
        text = args.shift
        @x.tag! :p, *args do
          @x.indented_text! text
        end
      else
        super
      end
    end

    def _svg(*args, &block)
      args << {} if args.empty?
      args.first['xmlns'] = 'http://www.w3.org/2000/svg' if Hash === args.first
      @x.proxiable_tag! :svg, *args, &block
    end

    def _math(*args, &block)
      args << {} if args.empty?
      if Hash === args.first
        args.first['xmlns'] = 'http://www.w3.org/1998/Math/MathML'
      end
      @x.proxiable_tag! :math, *args, &block
    end
    
    def _pre(*args, &block)
      args.first.chomp! if String === args.first and args.first.end_with? "\n"
      @x.disable_indentation! { @x.tag! :pre, *args, &block }
    end

    def _!(text)
      @x.text! text.to_s
    end

    def _(text=nil, &block)
      unless block
        if text
          if Proc === text
            instance_eval &text
          elsif text.respond_to? :html_safe? and text.html_safe?
            _ {text}
          else
            @x.indented_text! text.to_s
          end
        end
        return @x
      end

      children = block.call

      if String === children
        safe = !children.tainted?
        safe ||= children.html_safe? if children.respond_to? :html_safe?

        if safe and (children.include? '<' or children.include? '&')
          require 'nokogiri'
          children = Nokogiri::HTML::fragment(children.to_s).children
        else
          return @x.indented_text! children
        end
      end
      @x[*children]
    end

    def _coffeescript(text)
      require 'coffee-script'
      _script CoffeeScript.compile(text)
    rescue LoadError
      _script text, :lang => 'text/coffeescript'
    end

    def clear!
      @x.target!.clear
    end

    def self.flatten?(children)
      # do any of the text nodes need special processing to preserve spacing?
      flatten = false
      space = true
      if children.any? {|child| child.text? and !child.text.strip.empty?}
        children.each do |child|
          if child.text? or child.element?
            unless child.text == ''
              flatten = true if not space and not child.text =~ /\A\s/
              space = (child.text =~ /\s\Z/)
            end
            space = true if child.element? and HTML5_BLOCK.include? child.name
          end
        end
      end
      flatten
    end

    # reflow long lines
    def self.reflow(stream, width)
      source = stream.slice!(0..-1)
      indent = col = 0
      breakable = true
      pre = false
      while not source.empty?
        token = source.shift
        indent = token[/^ */].length if col == 0

        if token.start_with? '<'
          breakable = false
          pre = true if token == '<pre'
        end

        # flow text
        while token.length + col > width and breakable and not pre
          break if token[0...-1].include? "\n"
          split = token.rindex(' ', [width-col,0].max) || token.index(' ')
          break unless split
          break if col+split < indent+width/2
          stream << token[0...split] << "\n" << (' '*indent)
          col = indent
          token = token[split+1..-1]
        end

        # break around tags
        if token.end_with? '>'
          if col > indent + 4 and stream[-2..-1] == ['<br', '/']
            stream << token << "\n"
            col = 0
            token = ' '*indent
            source[0] = source.first.lstrip unless source.empty?
          elsif col > width and not pre
            # break on previous space within text
            pcol = col
            stream.reverse_each do |xtoken|
              break if xtoken.include? "\n"
              split = xtoken.rindex(' ')
              breakable = false if xtoken.end_with? '>'
              if breakable and split
                col = col - pcol + xtoken.length - split + indent
                xtoken[split] = "\n#{' '*indent}" 
                break
              end
              breakable = true if xtoken.start_with? '<'
              pcol -= xtoken.length
              break if pcol < (width + indent)/2
            end
          end
          breakable = true
          pre = false if token == '</pre>'
        end

        stream << token
        col += token.length
        col = 0 if token.end_with? "\n"
      end
    end
  end
end
