# Wrapper class that understands HTML
class HtmlMarkup < Wunderbar::BuilderBase
  VOID = %w(
    area base br col command embed hr img input keygen
    link meta param source track wbr
  )

  HTML5_BLOCK = %w(
    # https://developer.mozilla.org/en/HTML/Block-level_elements
    address article aside audio blockquote br canvas dd div dl fieldset
    figcaption figcaption figure footer form h1 h2 h3 h4 h5 h6 header hgroup hr
    noscript ol output p pre section table tfoot ul video
  )

  def initialize(scope)
    @_scope = scope
    @x = Wunderbar::XmlMarkup.new :scope => scope, :indent => 2, :target => []
    @xthml = false
  end

  def xhtml(*args, &block)
    @xhtml = true
    html(*args, &block)
  end

  def html(*args, &block)
    # default namespace
    args << {} if args.empty?
    args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml' if Hash === args.first
    @_width = args.first.delete(:_width) if Hash === args.first

    @x.text! "\xEF\xBB\xBF"
    @x.declare! :DOCTYPE, :html
    @x.tag! :html, *args do 
      set_variables_from_params
      instance_eval(&block)
    end

    if @_width
      # reflow long lines
      source = @x.target!.slice!(0..-1)
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

        while token.length + col > @_width and breakable and not pre
          break if token[0...-1].include? "\n"
          split = token.rindex(' ', [@_width-col,0].max) || token.index(' ')
          break unless split
          break if col+split < indent+@_width/2
          @x.target! << token[0...split] << "\n" << (' '*indent)
          col = indent
          token = token[split+1..-1]
        end

        if token.end_with? '>'
          breakable = true
          pre = false if token == '</pre>'
        end

        @x.target! << token
        col += token.length
        col = 0 if token.end_with? "\n"
      end
    end

    @x.target!.join
  end

  def _html(*args, &block)
    html(*args, &block)
  end

  def _xhtml(*args, &block)
    @xhtml = true
    html(*args, &block)
  end

  def xhtml?
    @xhtml
  end

  def method_missing(name, *args, &block)
    if name.to_s =~ /^_(\w+)(!|\?|)$/
      name, flag = $1, $2
    elsif @_scope and @_scope.respond_to? name
      return @_scope.__send__ name, *args, &block
    else
      error = NameError.new "undefined local variable or method `#{name}'", name
      error.set_backtrace caller
      raise error
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
      if args.length == 0 or (args.length == 1 and Hash === args.first)
        args.unshift '' if not VOID.include?(name) and not block
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

  def _?(text)
    @x.indented_text! text
  end

  def _!(text)
    @x.text! text
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

  def _(children=nil)
    return @x if children == nil

    if String === children
      if children.include? '<' or children.include? '&'
        require 'nokogiri'
        children = Nokogiri::HTML::fragment(children.to_s).children
      else
        return @x.indented_text! children
      end
    end

    # remove leading and trailing space
    children.shift if children.first.text? and children.first.text.strip.empty?
    if not children.empty?
      children.pop if children.last.text? and children.last.text.strip.empty?
    end

    children.each do |child|
      if child.text? or child.cdata?
        text = child.text
        if text.strip.empty?
          @x.text! "\n" if text.count("\n")>1
        elsif @x.indentation_state!.first == 0
          @x.indented_text! text.gsub(/\s+/, ' ')
        else
          @x.indented_text! text.strip
        end
      elsif child.comment?
        @x.comment! child.text.sub(/\A /,'').sub(/ \Z/, '')
      elsif self.class.flatten? child.children
        block_element = Proc.new do |node| 
          node.element? and HTML5_BLOCK.include?(node.name)
        end

        if child.children.any?(&block_element)
          # indent children, but disable indentation on consecutive
          # sequences of non-block-elements.  Put another way: break
          # out block elements to a new line.
          @x.tag!(child.name, child.attributes) do
            children = child.children.to_a
            while not children.empty?
              stop = children.index(&block_element)
              if stop == 0
                _ [children.shift]
              else
                @x.disable_indentation! do
                  _ children.shift(stop || children.length)
                end
              end
            end
          end
        else
          # disable indentation on the entire element
          @x.disable_indentation! do
            @x.tag!(child.name, child.attributes) {_ child.children}
          end
        end
      elsif child.children.empty?
        @x.tag!(child.name, child.attributes)
      elsif child.children.all? {|gchild| gchild.text?}
        @x.tag!(child.name, child.text.strip, child.attributes)
      elsif child.children.any? {|gchild| gchild.cdata?} and 
        (child.text.include? '<' or child.text.include? '&')
        @x << child
      else
        @x.tag!(child.name, child.attributes) {_ child.children}
      end
    end
  end
end
