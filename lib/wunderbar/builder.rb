module Wunderbar
  # XmlMarkup handles indentation of elements beautifully, this class extends
  # that support to text, data, and spacing between elements
  class SpacedMarkup < Builder::XmlMarkup
    def indented_text!(text)
      indented_data!(text) {|data| text! data}
    end

    def indented_data!(data, pre=nil, post=nil, &block)
      return if data.strip.length == 0

      self << pre + target!.pop if pre

      if @indent > 0
        data = data.sub(/\n\s*\Z/, '').sub(/\A\s*\n/, '')

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

      self << post if post
    end

    def disable_indentation!(&block)
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
      # workaround for https://github.com/jimweirich/builder/commit/7c824996637d2d76455c87ad47d76ba440937e38
      sym = "#{sym}:#{args.shift}" if args.first.kind_of?(::Symbol)
      if not block and args.first == ''
        attrs = {}
        attrs.merge!(args.last) if ::Hash === args.last
        _indent
        _start_tag(sym, attrs)
        _end_tag(sym)
        _newline
      else
        super
      end
    end
  end

  class BuilderBase
    def set_variables_from_params(locals={})
      @_scope.params.merge(locals).each do |key,value|
        value = value.first if Array === value
        value.gsub! "\r\n", "\n" if String === value
        if key =~ /^[a-z]\w+$/
          instance_variable_set "@#{key.dup.untaint}", value 
        end
      end
    end

    def get_binding
      binding
    end
  end

  class BuilderClass < BuilderBase
    def websocket(*args, &block)
      if Hash === args.last
        args.last[:locals] = Hash[instance_variables.
          map { |name| [name.sub('@',''), instance_variable_get(name)] } ]
      end
      Wunderbar.websocket(*args, &block)
    end
  end

  class XmlMarkup < BuilderClass
    def initialize(args)
      @_scope = args.delete(:scope)
      @_builder = SpacedMarkup.new(args)
      @_pdf = false
    end

    # forward to Wunderbar, XmlMarkup, or @_scope
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        Wunderbar.send method, *args, &block
      elsif SpacedMarkup.public_instance_methods.include? method
        @_builder.__send__ method, *args, &block
      elsif SpacedMarkup.public_instance_methods.include? method.to_s
        @_builder.__send__ method, *args, &block
      elsif @_scope and @_scope.respond_to? method
        @_scope.send method, *args, &block
      else
        super
      end
    end

    def methods
      result = super + Wunderbar.methods
      result += SpacedMarkup.public_instance_methods
      result += @_scope.methods if @_scope
      result.uniq
    end

    def respond_to?(method)
      respond true if Wunderbar.respond_to? method
      respond true if SpacedMarkup.public_instance_methods.include? method
      respond true if SpacedMarkup.public_instance_methods.include?  method.to_s
      respond true if @_scope and @_scope.respond_to? method?
      super
    end

    # expose a new attribute
    def attr_accessor(*names)
      (class << self; self; end).instance_eval {attr_accessor *names}
    end

    # avoid method_missing overhead for the most common case
    def tag!(sym, *args, &block)
      if sym.respond_to? :children
        node = sym
        attributes = node.attributes
        if node.attribute_nodes.any?(&:namespace)
          attributes = Hash[node.attribute_nodes.map { |attr| 
            name = attr.name
            name = "#{attr.namespace.prefix}:#{name}" if attr.namespace
            [name, attr.value]
          }]
        end
        attributes.merge!(node.namespaces) if node.namespaces
        args.push attributes
        if node.namespace and node.namespace.prefix
          args.unshift node.name.to_sym
          sym = node.namespace.prefix
        else
          sym = node.name
        end
      end

      if !block and (args.empty? or args == [''])
        CssProxy.new(@_builder, @_builder.target!, sym, args)
      else
        @_builder.tag! sym, *args, &block
      end
    end

    def proxiable_tag!(sym, *args, &block)
      if block
        tag!(sym, *args, &block)
      else
        CssProxy.new(@_builder, @_builder.target!, sym, args)
      end
    end

    def pdf=(value)
      @_pdf = value
    end

    def pdf?
      @_pdf
    end

    # execute a system command, echoing stdin, stdout, and stderr
    def system(command, opts={})
      if command.respond_to? :flatten
        flat = command.flatten
        secret = command - flat
        begin
          # if available, use escape as it does prettier quoting
          require 'escape'
          echo = Escape.shell_command(command.compact - secret)
        rescue LoadError
          # std-lib function that gets the job done
          require 'shellwords'
          echo = Shellwords.join(command.compact - secret)
        end
        command = flat.compact.map(&:dup).map(&:untaint)
      else
        echo = command
        command = [command]
      end
      
      patterns = opts[:hilite] || []
      patterns=[patterns] if String === patterns or Regexp === patterns
      patterns.map! do |pattern| 
        String === pattern ? Regexp.new(Regexp.escape(pattern)) : pattern
      end

      require 'open3'
      tag  = opts[:tag]  || 'pre'
      output_class = opts[:class] || {}
      stdin  = output_class[:stdin]  || '_stdin'
      stdout = output_class[:stdout] || '_stdout'
      stderr = output_class[:stderr] || '_stderr'
      hilite = output_class[:hilite] || '_stdout _hilite'

      @_builder.tag! tag, echo, :class=>stdin unless opts[:echo] == false

      require 'thread'
      semaphore = Mutex.new
      Open3.popen3(*command) do |pin, pout, perr, wait|
        [
          Thread.new do
            until pout.eof?
              out_line = pout.readline.chomp
              semaphore.synchronize do
                if patterns.any? {|pattern| out_line =~ pattern}
                  @_builder.tag! tag, out_line, :class=>hilite
                else
                  @_builder.tag! tag, out_line, :class=>stdout
                end
              end
            end
          end,

          Thread.new do
            until perr.eof?
              err_line = perr.readline.chomp
              semaphore.synchronize do 
                @_builder.tag! tag, err_line, :class=>stderr
              end
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
        wait and wait.value.exitstatus
      end
    end

    # declaration (DOCTYPE, etc)
    def declare(*args)
      @_builder.declare!(*args)
    end

    # comment
    def comment(*args)
      @_builder.comment! *args
    end

    # insert verbatim
    def <<(data)
      if not String === data or data.include? '<' or data.include? '&'
        require 'nokogiri'
        data = Nokogiri::HTML::fragment(data.to_s).to_xml
      end

      # fix CDATA in most cases (notably scripts)
      data.gsub!(/<!\[CDATA\[(.*?)\]\]>/m) do |cdata|
        if $1.include? '<' or $1.include? '&'
          "//<![CDATA[\n#{$1}\n//]]>"
        else
          $1
        end
      end

      # fix CDATA for style elements
      data.gsub!(/<style([^>])*>\/\/<!\[CDATA\[\n(.*?)\s+\/\/\]\]>/m) do |cdata|
        if $2.include? '<' or $2.include? '&'
          "<style#{$1}>/*<![CDATA[*/\n#{$2.gsub("\n\Z",'')}\n/*]]>*/"
        else
          $1
        end
      end

      @_builder << data
    rescue LoadError
      @_builder << data
    end

    def [](*children)
      if children.length == 1 and children.first.respond_to? :root
        children = [children.first.root]
      end

      # remove leading and trailing space
      if children.first.text? and children.first.text.strip.empty?
        children.shift
      end

      if not children.empty?
        children.pop if children.last.text? and children.last.text.strip.empty?
      end

      children.each do |child|
        if child.text? or child.cdata?
          text = child.text
          if text.strip.empty?
            text! "\n" if text.count("\n")>1
          elsif indentation_state!.first == 0
            indented_text! text
          else
            indented_text! text.strip
          end
        elsif child.comment?
          comment! child.text.sub(/\A /,'').sub(/ \Z/, '')
        elsif HtmlMarkup.flatten? child.children
          block_element = Proc.new do |node| 
            node.element? and HtmlMarkup::HTML5_BLOCK.include?(node.name)
          end

          if child.children.any?(&block_element)
            # indent children, but disable indentation on consecutive
            # sequences of non-block-elements.  Put another way: break
            # out block elements to a new line.
            tag!(child) do
              children = child.children.to_a
              while not children.empty?
                stop = children.index(&block_element)
                if stop == 0
                  self[children.shift]
                else
                  disable_indentation! do
                    self[*children.shift(stop || children.length)]
                  end
                end
              end
            end
          else
            # disable indentation on the entire element
            disable_indentation! do
              tag!(child) {self[*child.children]}
            end
          end
        elsif child.children.empty? and HtmlMarkup::VOID.include? child.name
          tag!(child)
        elsif child.children.all?(&:text?)
          tag!(child, child.text.strip)
        elsif child.children.any?(&:cdata?) and child.text =~ /[<&]/
          self << child
        else
          tag!(child) {self[*child.children]}
        end
      end
    end
  end

  require 'stringio'
  class TextBuilder < BuilderClass
    def initialize(scope)
      @_target = StringIO.new
      @_scope = scope
    end

    def encode(&block)
      set_variables_from_params
      self.instance_eval(&block)
      @_target.string
    end

    def _(*args)
      @_target.puts *args if args.length > 0 
      self
    end

    # forward to Wunderbar, @_target, or @_scope
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        return Wunderbar.send method, *args, &block
      elsif @_target.respond_to? method
        return @_target.send method, *args, &block
      elsif @_scope and @_scope.respond_to? method
        return @_scope.send method, *args, &block
      else
        super
      end
    end

    def _exception(*args)
      exception = args.first
      if exception.respond_to? :backtrace
        Wunderbar.error exception.inspect
        @_target.puts unless size == 0
        @_target.puts exception.inspect
        exception.backtrace.each do |frame| 
          next if CALLERS_TO_IGNORE.any? {|re| frame =~ re}
          Wunderbar.warn "  #{frame}"
          @_target.puts "  #{frame}"
        end
      else
        super
      end
    end

    def target!
      @_target.string
    end
  end

  class JsonBuilder < BuilderClass
    def initialize(scope)
      @_scope = scope
      @_target = {}
    end

    def encode(&block)
      set_variables_from_params
      self.instance_eval(&block)
      @_target
    end

    # expose a new attribute
    def attr_accessor(*names)
      (class << self; self; end).instance_eval {attr_accessor *names}
    end

    # forward to Wunderbar, @_target, or @_scope
    def method_missing(method, *args, &block)

      if method.to_s =~ /^_(\w*)$/
        name = $1
      elsif Wunderbar.respond_to? method
        return Wunderbar.send method, *args, &block
      elsif @_target.respond_to? method
        return @_target.send method, *args, &block
      elsif @_scope and @_scope.respond_to? method
        return @_scope.send method, *args, &block
      elsif TOPLEVEL_BINDING.eval('local_variables').include? method
        return TOPLEVEL_BINDING.eval(method.to_s)
      else
        super
      end

      if args.length == 0
        return self unless block
        result = JsonBuilder.new(@_scope).encode(&block)
      elsif args.length == 1
        result = args.first

        if block
          if Symbol === result or String === result
            result = {result.to_s => JsonBuilder.new(@_scope).encode(&block)}
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
          result = []
          result = @_target if name.empty? and @_target.respond_to? :<<
          object.each do |item|
            result << Hash[args.map {|arg| [arg.to_s, item.send(arg)]}]
          end
        end
      end

      if name != ''
        unless Hash === @_target or @_target.empty?
          ::Kernel::raise ::ArgumentError, "mixed array and hash calls"
        end

        @_target[name.to_s] = result
      elsif args.length == 0 or (args.length == 1 and not block)
        if Proc === result
          instance_eval &result 
        else
          @_target = [] if @_target == {}

          if Hash === @_target 
            ::Kernel::raise ::ArgumentError, "mixed hash and array calls"
          end

          @_target << result
        end
      else
        @_target = result
      end

      self
    end

    def _!(object)
      @_target = object
    end

    def _exception(*args)
      exception = args.first
      if exception.respond_to? :backtrace
        Wunderbar.error exception.inspect
        super(exception.inspect)
        @_target['backtrace'] = []
        exception.backtrace.each do |frame| 
          next if CALLERS_TO_IGNORE.any? {|re| frame =~ re}
          Wunderbar.warn "  #{frame}"
          @_target['backtrace'] << frame 
        end
      else
        super
      end
    end

    def target!
      begin
        JSON.pretty_generate(@_target)+ "\n"
      rescue
        @_target.to_json + "\n"
      end
    end
  end

  # make it easier to define extensions
  class Extension
    def self.proc(name, &block)
      (class << self; self; end).instance_eval do
        define_method(name) {Proc.new &block}
      end
    end
  end
end
