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

    HEAD = %w(title base link style meta)

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

      if ''.respond_to? :encoding
        bom = "\ufeff"
      else
        bom = "\xEF\xBB\xBF"
      end

      @x.declare! :DOCTYPE, :html
      html = @x.tag! :html, *args do 
        set_variables_from_params
        instance_eval(&block)
      end

      pending_head = []
      pending_body = []
      head = nil
      body = nil
      html.children.each do |child| 
        next unless child
        if child.name == 'head'
          head = child
        elsif child.name == 'body'
          body = child
        elsif HEAD.include? child.name
          pending_head << child
        elsif child.name == 'script'
          if pending_body.empty?
            pending_head << child
          else
            pending_body << child
          end
        else
          pending_body << child
        end
      end

      @x.instance_eval {@node = html}
      head = _head_ if not head
      body = _body nil if not body
      html.children.unshift(head.parent.children.delete(head))
      html.children.push(body.parent.children.delete(body))
      head.parent = body.parent = html
      head.children.compact!
      body.children.compact!

      [ [pending_head, head], [pending_body, body] ].each do |list, node|
        list.each do |child|
          html.children.delete(child)
          node.add_child child
        end
      end

      if not head.children.any? {|child| child.name == 'title'}
        h1 = body.children.find {|child| child.name == 'h1'}
        head.add_child Node.new('title', h1.text) if h1 and h1.text
      end

      bom + @x.target!
    end

    def _html(*args, &block)
      html(*args, &block)
    end

    def method_missing(name, *args, &block)
      if name =~ /^_(\w+)(!|\?|)$/
        name, flag = $1, $2
      elsif @_scope and @_scope.respond_to? name
        return @_scope.__send__ name, *args, &block
      else
        err = NameError.new "undefined local variable or method `#{name}'", name
        err.set_backtrace caller
        raise err
      end

      if name.sub!(/_$/,'')
        @x.spaced!
        return __send__ "_#{name}", *args, &block if respond_to? "_#{name}"
      end

      name = name.to_s.gsub('_', '-')

      if flag != '!'
        if %w(script style).include?(name)
          args << {} unless Hash === args.last
          args.last[:lang] ||= 'text/javascript' if name == 'script'
          args.last[:type] ||= 'text/css' if name == 'style'
        end

        if String === args.first and args.first.respond_to? :html_safe?
          if args.first.html_safe? and not block and args.first =~ /[>&]/
            markup = args.shift
            block = Proc.new {_ {markup}}
          end
        end
      end

      if flag == '!'
        @x.compact!(@_width) { @x.tag! name, *args, &block }
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
        @x.tag! name, *args, &block
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
      @x.compact!(@_width) { @x.tag! :pre, *args, &block }
    end

    def _!(text)
      @x.text! text.to_s.chomp
    end

    def _(text=nil, &block)
      unless block
        if text
          if text.respond_to? :html_safe? and text.html_safe?
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
  end
end
