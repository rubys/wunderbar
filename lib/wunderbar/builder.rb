require 'shellwords'
require 'open3'
require 'thread'

module Wunderbar
  @@options = {indent: 2}
  def self.option(values={})
    @@options.merge!(values)
    @@options
  end

  class BuilderBase
    def set_variables_from_params(locals={})
      params = []
      @_scope.params.each_pair do |key, value|
        value = value.first if Array === value
        value.gsub! "\r\n", "\n" if String === value
        params << ["@#{key}", value]
      end

      Hash[params].merge(locals).each do |key,value|
        if key =~ /^@[a-z]\w+$/
          instance_variable_set key, value 
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
          map { |name| [name.to_s.sub('@',''), instance_variable_get(name)] } ]
      end
      Wunderbar.websocket(*args, &block)
    end

    # execute a system command, echoing stdin, stdout, and stderr
    def system(*args)
      opts = {}
      opts = args.pop if Hash === args.last
      command = args
      command = args.first if args.length == 1 and Array === args.first

      if command.respond_to? :flatten
        flat = command.flatten
        secret = command - flat
        begin
          # if available, use escape as it does prettier quoting
          raise LoadError if $SAFE > 0 and not defined? Escape
          require 'escape'
          echo = Escape.shell_command(command.compact - secret)
        rescue LoadError
          # std-lib function that gets the job done
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

      yield :stdin, echo unless opts[:echo] == false

      semaphore = Mutex.new
      env = {'LC_CTYPE' => 'en_US.UTF-8'}
      Open3.popen3(env, *command) do |pin, pout, perr, wait|
        [
          Thread.new do
            until pout.eof?
              out_line = pout.readline.chomp
              semaphore.synchronize do
                if patterns.any? {|pattern| out_line =~ pattern}
                  yield :hilite, out_line
                else
                  yield :stdout, out_line
                end
              end
            end
          end,

          Thread.new do
            until perr.eof?
              err_line = perr.readline.chomp
              semaphore.synchronize do
                yield :stderr, err_line
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
  end

  class XmlMarkup < BuilderClass
    # convenience method for taking an XML node or string and formatting it
    def self.dump(content, args={})
      markup = self.new(args)

      if Nokogiri::XML::Document === content and content.root.name == 'html'
        markup.declare! :DOCTYPE, :html
      end

      unless Nokogiri::XML::Node === content
        if defined? Nokogiri::HTML5.fragment
          content = Nokogiri::HTML5.fragment(content.to_s)
        else
          content = Nokogiri::HTML.fragment(content.to_s)
        end
      end

      markup[content]
      markup.target!
    end

    def initialize(args={})
      @_scope = args.delete(:scope)
      @_indent = args.delete(:indent) || Wunderbar.option[:indent]
      @_width = args.delete(:width) || Wunderbar.option[:width]
      @_pdf = false
      @doc = Node.new(nil)
      @node = @doc
      @indentation_enabled = true
      @spaced = false
    end

    attr_accessor :_width

    # forward to Wunderbar or @_scope
    def method_missing(method, *args, &block)
      if Wunderbar.respond_to? method
        Wunderbar.send method, *args, &block
      elsif @_scope and @_scope.respond_to? method
        @_scope.send method, *args, &block
      else
        super
      end
    end

    def methods
      result = super + Wunderbar.methods
      result += @_scope.methods if @_scope
      result.uniq
    end

    def respond_to?(method)
      respond true if Wunderbar.respond_to? method
      respond true if @_scope and @_scope.respond_to? method
      super
    end

    def text! text
      @node.children << TextNode.new(text)
    end

    def declare! *args
      @node.children << DocTypeNode.new(*args)
    end

    def comment! text
      @node.children << CommentNode.new(text)
    end

    def indented_text!(text)
      return if text.length == 0 and not @spaced
      text = IndentedTextNode.new(text)
      text.extend SpacedNode if @spaced
      @node.children << text
      @spaced = false
    end

    def target!
      "#{@doc.serialize(indent: ' ' * @_indent, width: @_width).join("\n")}\n"
    end

    def clear!
      @doc.children.clear
      @node = @doc
    end

    def compact!(&block)
      begin
        indentation_enabled, @indentation_enabled = @indentation_enabled, false
        block.call
      ensure
        @indentation_enabled = indentation_enabled
      end
    end

    def spaced!
      @spaced = true
    end

    # avoid method_missing overhead for the most common case
    def tag!(sym, *args, &block)
      current_node = @node

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
          sym = "#{node.namespace.prefix}:#{node.name}"
        else
          sym = node.name
        end

        unless Class === args.first
          args.unshift PreformattedNode if sym == 'pre'
          args.unshift ScriptNode if sym == 'script'
          args.unshift StyleNode if sym == 'style'
        end
      end

      children = nil
      if block and block.arity !=0
        if args.first and args.first.respond_to? :each
          children = args.shift
        end
      end

      if Class === args.first and args.first < Node
        node = args.shift.new sym, *args
      else
        node = Node.new sym, *args
      end

      node.extend CompactNode unless @indentation_enabled

      if @spaced
        node.extend SpacedNode
        @spaced = false
      end

      node.text = args.shift if String === args.first
      @node.add_child node
      @node = node
      if block
        if children
          children.each {|child| block.call(child)}
        else
          block.call(self)
        end
        @node.children << nil if @node.children.empty?
      end

      node
    ensure
      @node = current_node
    end

    def pdf=(value)
      @_pdf = value
    end

    def pdf?
      @_pdf
    end

    # execute a system command, echoing stdin, stdout, and stderr
    def system(*args)
      opts = {}
      opts = args.pop if Hash === args.last
      command = args
      command = args.first if args.length == 1 and Array === args.first

      tag  = opts[:tag]  || 'pre'
      output_class = opts[:class] || {}
      output_class[:stdin]  ||= '_stdin'
      output_class[:stdout] ||= '_stdout'
      output_class[:stderr] ||= '_stderr'
      output_class[:hilite] ||= '_stdout _hilite'

      super do |kind, line|
        tag! tag, line, class: output_class[kind]
      end
    end

    # insert verbatim
    def <<(data)
      if defined? Nokogiri
        if not String === data or data.include? '<' or data.include? '&'
          # https://github.com/google/gumbo-parser/issues/266
          data = Nokogiri::HTML::fragment(data.to_s).to_xml

          # fix CDATA in most cases (notably scripts)
          data.gsub!(/<!\[CDATA\[(.*?)\]\]>/m) do
            if $1.include? '<' or $1.include? '&'
              "//<![CDATA[\n#{$1}\n//]]>"
            else
              $1
            end
          end

          # fix CDATA for style elements
          data.gsub!(/<style([^>])*>\/\/<!\[CDATA\[\n(.*?)\s+\/\/\]\]>/m) do
            if $2.include? '<' or $2.include? '&'
              "<style#{$1}>/*<![CDATA[*/\n#{$2.gsub("\n\Z",'')}\n/*]]>*/"
            else
              $1
            end
          end
        end
      end

      if String === data
        @node.children << data
      else
        @node.add_child data
      end
    end

    def [](*children)
      if children.length == 1
        if children.first.respond_to? :root
          children = [children.first.root]
        elsif defined? Nokogiri::XML::DocumentFragment and
          Nokogiri::XML::DocumentFragment === children.first
        then
          children = children.first.children
        end
      end

      # remove leading and trailing space
      if children.first.text? and children.first.text.strip.empty?
        children.shift
      end

      if not children.empty?
        children.pop if children.last.text? and children.last.text.strip.empty?
      end

      children.map do |child|
        if child.text? or child.cdata?
          text = child.text
          if not @indentation_enabled
            text! text
          elsif text.strip.empty?
            text! "" if text.count("\n")>1
          else
            indented_text! text
          end
        elsif child.comment?
          comment! child.text.sub(/\A /,'').sub(/ \Z/, '')
        elsif HtmlMarkup.flatten? child.children
          # disable indentation on the entire element
          compact! { tag!(child) {self[*child.children]} }
        elsif child.children.empty? and HtmlMarkup::VOID.include? child.name
          tag!(child)
        elsif child.children.all?(&:text?) and child.text
          tag!(child, @indentation_enabled ? child.text.strip : child.text)
        elsif child.children.any?(&:cdata?) and child.text =~ /[<&]/
          self << child
        elsif child.name == 'pre'
          compact! { tag!(child) {self[*child.children]} }
        elsif child.name == 'head'
          head = tag!(child) {self[*child.children]}
          html = @doc.children.last
          if html.name == :html
            head.parent.children.pop
            html.children.unshift head
            head.parent = html
          end
          head
        elsif not Nokogiri::XML::DTD === child
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
      before = @_target.string
      result = self.instance_eval(&block)
      _ result if before.empty? and result and @_target.string == before
      @_target.string
    end

    def _(*args)
      @_target.puts(*args) if args.length > 0 
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

    # execute a system command, echoing stdin, stdout, and stderr
    def system(*args)
      opts = {}
      opts = args.pop if Hash === args.last
      command = args
      command = args.first if args.length == 1 and Array === args.first

      output_prefix = opts[:prefix] || {}
      output_prefix[:stdin]  ||= '$ '

      super do |kind, line|
        @_target.puts "#{output_prefix[kind]}#{line}"
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
      before = @_target.dup
      result = self.instance_eval(&block)
      _! result if before.empty? and result and @_target == before
      @_target
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

    # execute a system command, echoing stdin, stdout, and stderr
    def system(*args)
      opts = {}
      opts = args.pop if Hash === args.last
      command = args
      command = args.first if args.length == 1 and Array === args.first

      transcript = opts[:transcript]  || 'transcript'
      output_prefix = opts[:prefix] || {}
      output_prefix[:stdin]  ||= '$ '

      if @_target[transcript]
        @_target[transcript] << ''
      else
        @_target[transcript] = []
      end

      super do |kind, line|
        @_target[transcript] << "#{output_prefix[kind]}#{line}"
      end
    end

    # execute a system command, ensuring the result is a success
    def system!(*args)
      rc = system(args)
      
      raise RuntimeError.new("exit code: #{rc}") if rc != 0

      rc
    end

    def target!
      begin
        JSON.pretty_generate(@_target)+ "\n"
      rescue
        @_target.to_json + "\n"
      end
    end

    def target?(type=nil)
      if Class === type
        type === @_target
      else
        @_target
      end
    end
  end
end
