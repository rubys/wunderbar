# Wrapper class that understands HTML
module Wunderbar
  # factored out so that these methods can be overriden (e.g., by opal.rb)
  class Overridable < BuilderBase
    def _script(*args, &block)
      args << {} unless Hash === args.last
      args.last[:lang] ||= 'text/javascript'
      proxiable_tag! 'script', ScriptNode, *args, &block
    end

    def _style(*args, &block)
      if args == [:system]
        args[0] = %{
          pre._stdin {font-weight: bold; color: #800080; margin: 1em 0 0 0}
          pre._stdout {font-weight: bold; color: #000; margin: 0}
          pre._stderr {font-weight: bold; color: #F00; margin: 0}
        }
      end
      args << {} unless Hash === args.last
      args.last[:type] ||= 'text/css'
      proxiable_tag! 'style', StyleNode, *args, &block
    end
  end

  class HtmlMarkup < Overridable
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
      @_x = XmlMarkup.new :scope => scope, :indent => 2
    end

    def html(*args, &block)
      # default namespace
      args << {} if args.empty?
      if Hash === args.first
        args.first[:xmlns] ||= 'http://www.w3.org/1999/xhtml'
        @_x.width = args.first.delete(:_width).to_i if args.first[:_width]
      end

      bom = "\ufeff"

      title = args.shift if String === args.first
      @_x.declare! :DOCTYPE, :html
      html = tag! :html, *args do 
        set_variables_from_params
        _title title if title
        instance_eval(&block)
      end

      pending_head = []
      pending_body = []
      head = nil
      body = nil
      html.children.each do |child| 
        next unless child 
        if String === child
          pending_body << child
        elsif child.name == 'head'
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

      @_x.instance_eval {@node = html}
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

      def find_name(name)
        proc {|child| child.respond_to? :name and child.name == name}
      end

      if not head.children.any? &find_name('title')
        h1 = body.children.find &find_name('h1')
        head.add_child Node.new('title', h1.text) if h1 and h1.text
      end

      base = head.children.index &find_name('base')
      if base
        head.children.insert 1, head.children.delete_at(base) if base > 1

        # compute relative path from base to the current working directory
        require 'pathname'
        base = @_scope.env['DOCUMENT_ROOT'] if @_scope.env.respond_to? :[]
        base ||= Dir.pwd
        base += (head.children[1].attrs[:href] || '')
        base += 'index.html' if base.end_with? '/'
        base = Pathname.new(base).parent
        prefix = Pathname.new(Dir.pwd).relative_path_from(base).to_s + '/'
        prefix = nil if prefix == './'
  
        head.children.insert 2, *Asset.declarations(head, prefix)
      else
        head.children.insert 1, *Asset.declarations(head, nil)
      end

      title = head.children.index {|child| child.name == 'title'}
      if title and title > 1
        head.children.insert 1, head.children.delete_at(title)
      end

      bom + @_x.target!
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
        @_x.spaced!
        if flag != '!' and respond_to? "_#{name}"
          return __send__ "_#{name}#{flag}", *args, &block 
        end
      end

      name = name.to_s.gsub('_', '-')

      if flag != '!'
        if String === args.first and args.first.respond_to? :html_safe?
          if args.first.html_safe? and not block and args.first =~ /[>&]/
            markup = args.shift
            block = Proc.new {_ {markup}}
          end
        end
      end

      if flag == '!'
        @_x.compact! { tag! name, *args, &block }
      elsif flag == '?'
        # capture exceptions, produce filtered tracebacks
        tag!(name, *args) do
          begin
            block.call
          rescue ::Exception => exception
            options = (Hash === args.last)? args.last : {}
            options[:log_level] = 'warn'
            _exception exception, options
          end
        end
      elsif Wunderbar.templates.include? name
        x = self.class.new({})
        instance_variables.each do |ivar|
          x.instance_variable_set ivar, instance_variable_get(ivar)
        end
        if Hash === args.last
          args.last.each do |name, value|
            x.instance_variable_set "@#{name}", value
          end
        end
        save_yield = Wunderbar.templates['yield']
        begin
          Wunderbar.templates['yield'] = block if block
          x.instance_eval &Wunderbar.templates[name]
        ensure
          Wunderbar.templates['yield'] = save_yield
          Wunderbar.templates.delete 'yield' unless save_yield
        end
      else
        tag! name, *args, &block
      end
    end

    def tag!(name, *args, &block)
      node = @_x.tag! name, *args, &block
      if !block and args.empty?
        CssProxy.new(self, node)
      else
        node
      end
    end

    def proxiable_tag!(name, *args, &block)
      node = @_x.tag! name, *args, &block
      if !block
        CssProxy.new(self, node)
      else
        node
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
          tag! :pre, text, :class=>traceback_class
        else
          tag! :pre, text, :style=>traceback_style
        end
      else
        super
      end
    end

    def _head(*args, &block)
      tag!('head', *args) do
        tag! :meta, :charset => 'utf-8'
        block.call if block
      end
    end

    def _p(*args, &block)
      if args.length >= 1 and String === args.first and args.first.include? "\n"
        text = args.shift
        tag! :p, *args do
          @_x.indented_text! text
        end
      else
        super
      end
    end

    def _svg(*args, &block)
      args << {} if args.empty?
      args.first['xmlns'] = 'http://www.w3.org/2000/svg' if Hash === args.first
      proxiable_tag! :svg, *args, &block
    end

    def _math(*args, &block)
      args << {} if args.empty?
      if Hash === args.first
        args.first['xmlns'] = 'http://www.w3.org/1998/Math/MathML'
      end
      proxiable_tag! :math, *args, &block
    end
    
    def _pre(*args, &block)
      args.first.chomp! if String === args.first and args.first.end_with? "\n"
      @_x.compact! do
        proxiable_tag! :pre, PreformattedNode, *args, &block
      end
    end

    def _textarea(*args, &block)
      @_x.compact! do
        proxiable_tag! :textarea, PreformattedNode, *args, &block
      end
    end

    def _ul(*args, &block)
      iterable = args.first.respond_to? :each
      if iterable and (args.length > 1 or not args.first.respond_to? :to_hash)
        list = args.shift.dup
        tag!(:ul, *args) {list.each {|arg| _li arg }}
      else
        super
      end
    end

    def _ol(*args, &block)
      iterable = args.first.respond_to? :each
      if iterable and (args.length > 1 or not args.first.respond_to? :to_hash)
        list = args.shift
        tag!(:ol, *args) {list.each {|arg| _li arg }}
      else
        super
      end
    end

    def _tr(*args, &block)
      iterable = args.first.respond_to? :each
      if iterable and (args.length > 1 or not args.first.respond_to? :to_hash)
        list = args.shift
        tag!(:tr, *args) {list.each {|arg| _td arg }}
      else
        super
      end
    end

    def _!(text)
      @_x.text! text.to_s.chomp
    end

    def _(text=nil, &block)
      unless block
        if text
          if text.respond_to? :html_safe? and text.html_safe?
            _ {text}
          else
            @_x.indented_text! text.to_s
          end
        end
        return @_x
      end

      children = instance_eval &block

      if String === children
        safe = !children.tainted?
        safe ||= children.html_safe? if children.respond_to? :html_safe?
        safe &&= defined? Nokogiri
        ok = safe || defined? Sanitize
        safe = true

        if ok and (children.include? '<' or children.include? '&')
          if defined? Nokogiri::HTML5.fragment
            doc = Nokogiri::HTML5.fragment(children.to_s)
          else
            doc = Nokogiri::HTML.fragment(children.to_s)
          end

          Sanitize.new.clean_node! doc.dup.untaint if not safe
          children = doc.children.to_a

          # ignore leading whitespace
          while not children.empty? and children.first.text?
            break unless children.first.text.strip.empty?
            children.shift
          end

          # gather up candidate head elements
          pending_head = []
          while not children.empty? and children.first.element?
            break unless (HEAD+['script']).include? children.first.name
            pending_head << children.shift
          end

          # rebuild head element if any candidates were found
          unless pending_head.empty?
            head = Nokogiri::XML::Node.new('head', pending_head.first.document) 
            pending_head.each {|child| head << child}
            children.unshift head
          end
        else
          return @_x.indented_text! children
        end
      elsif children.nil? or Wunderbar::Node === children
        return children
      end

      @_x[*children]
    end

    def __(text=nil, &block)
      if text
        @_x.spaced!
        @_x.indented_text! text
      elsif block
        @_x.spaced!
        _ &block
      else
        @_x.text! ""
      end
    end

    def clear!
      @_x.clear!
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
