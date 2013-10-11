module Wunderbar
  class Node
    attr_accessor :name, :text, :attrs, :node, :children, :parent

    VOID = %w(
      area base br col command embed hr img input keygen
      link meta param source track wbr
    )

    ESCAPE = {
      "'" => '&apos;',
      '&' => '&amp;',
      '"' => '&quot;',
      '<' => '&lt;',
      '>' => '&gt;',
    }

    def initialize(name, *args)
      @name = name
      @text = nil
      @attrs = {}
      @children = []
      @name += args.shift.inspect if Symbol === args.first
      @attrs = args.pop.to_hash if args.last.respond_to? :to_hash
      @text = args.shift.to_s unless args.empty?
    end

    def method_missing(*args)
      if args.length == 0
        attrs[:class] = (attrs[:class].to_s.split(' ') + [name]).join(' ')
      else
        name = args.first.to_s
        err = NameError.new "undefined local variable or method `#{name}'", name
        err.set_backtrace caller
        raise err
      end
    end

    def add_child(child)
      @children << child
      child.parent = self
    end

    def add_text(text)
      @children << text.to_s.gsub(/[&<>]/,ESCAPE)
    end

    def walk(result, indent)
      indent += '  ' if indent and parent
      first = true
      spaced = false
      children.each do |child| 
        next unless child
        result << '' if (spaced or SpacedNode === child) and not first
        if String === child
          result << child
        else
          child.serialize(result, indent)
        end
        first = false
        spaced = (SpacedNode === child)
      end
    end

    def serialize(result = [], indent='', pre=nil, post=nil)
      line = "#{indent}<#{name}"

      attrs.each do |name, value| 
        next unless value
        name = name.to_s.gsub('_','-') if Symbol === name
        value=name if value==true
        line += " #{name}=\"#{value.to_s.gsub(/[&\"<>]/,ESCAPE)}\""
      end

      if children.empty? 
        if text
          if pre
            line += ">#{pre}#{text}#{post}</#{name}>"
          else
            line += ">#{text.to_s.gsub(/[&<>]/,ESCAPE)}</#{name}>"
          end
        elsif VOID.include? name.to_s
          line += "/>"
        else
          line += "></#{name}>"
        end
      elsif CompactNode === self
        work = []
        walk(work, nil)
        if @width
          line += ">"
          (work+["</#{name}>"]).each do |node|
            if line.length + node.length > @width
              result << line.rstrip
              line = indent
            end
            line += node
          end
        else
          line += ">#{work.join}</#{name}>"
        end
      else
        result <<  line+">#{pre}" if parent

        walk(result, indent) unless children.empty?

        line = "#{indent}#{post}</#{name}>"
      end

      result << line if parent
      result
    end
  end

  class CommentNode
    def initialize(text)
      @text = text
    end

    def serialize(result, indent)
      result << "#{indent}<!-- #{@text} -->"
      result
    end
  end

  class DocTypeNode
    def initialize(*args)
      @declare = args.shift
      @name = args.shift
    end

    def serialize(result, indent)
      result << "<!#{@declare} #{@name.to_s}>"
      result
    end
  end

  class CDATANode < Node
    def self.normalize(data, indent)
      data = data.sub(/\n\s*\Z/, '').sub(/\A\s*\n/, '')

      unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 0

      before  = ::Regexp.new('^'.ljust(unindent))
      node = @node
      data.gsub! before, indent
      data.gsub! /^#{indent}$/, '' if unindent == 0
      data
    end

    def serialize(result = [], indent='')
      if @text and @text.include? "\n"
        tindent = (indent ? "#{indent}  " : indent)
        children.unshift CDATANode.normalize(@text, tindent).rstrip
        @text = nil
      end

      if @text and @text =~ /[<^>]/
        indent += '  ' if indent
        children.unshift @text.gsub(/^/, indent).gsub(/^ +$/,'').rstrip
        @text = nil
        super(result, indent, pre, post)
      elsif children && children.any? {|node| String===node && node =~ /[<^>]/}
        super(result, indent, pre, post)
      else
        super
      end
    end

    def add_text(text)
      @children << text
    end
  end

  class IndentedTextNode < Node
    def serialize(result, indent)
      if indent
        text = CDATANode.normalize(name, indent)
      else
        text = name
      end

      result << text.to_s.gsub(/[&<>]/,ESCAPE)
    end
  end

  class ScriptNode < CDATANode
    def pre; "//<![CDATA["; end
    def post; "//]]>"; end
  end

  class StyleNode < CDATANode
    def pre; "/*<![CDATA[*/"; end
    def post; "/*]]>*/"; end
  end

  module CompactNode
    def width=(value)
      @width = value
    end
    def width
      @width
    end
  end

  module SpacedNode; end

end
