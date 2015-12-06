module Wunderbar
  class Node
    attr_accessor :name, :text, :attrs, :node, :children, :parent

    VOID = %w(
      area base br col command embed hr img input keygen
      link meta param source track wbr frame
    )

    ESCAPE = {
      "'" => '&apos;',
      '&' => '&amp;',
      '"' => '&quot;',
      '<' => '&lt;',
      '>' => '&gt;',
      "\u00A0" => '&#xA0;',
    }

    def initialize(name, *args)
      @name = name
      @text = nil
      @attrs = {}
      @children = []
      args -= symbols = args.find_all {|arg| Symbol === arg}
      @attrs = args.pop.to_hash if args.last.respond_to? :to_hash
      @text = args.shift.to_s unless args.empty?
      symbols.each {|sym| @attrs[sym] = true}
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

    def walk(result, indent, options)
      indent += options[:indent] if indent and parent
      first = true
      spaced = false

      if preserve_spaces?
        options = options.dup
        options[:space] = :preserve
      end

      children.each do |child| 
        next unless child
        result << '' if (spaced or SpacedNode === child) and not first
        if String === child
          child = child.gsub(/\s+/, ' ') unless options[:space] == :preserve
          result << child
        else
          child.serialize(options, result, indent)
        end
        first = false
        spaced = (SpacedNode === child)
      end
    end

    def serialize(options = {}, result = [], indent = '')
      line = "#{indent}<#{name}"

      attrs.each do |name, value| 
        next unless value
        name = name.to_s.gsub('_','-') if Symbol === name
        value=name if value==true
        line += " #{name}=\"#{value.to_s.gsub(/[&\"<>\u00A0]/,ESCAPE)}\""
      end

      if children.empty? 
        if options[:pre]
          line += ">#{options[:pre]}#{text}#{options[:post]}</#{name}>"
        else
          width = options[:width] unless preserve_spaces?

          if text
            line += ">#{text.to_s.gsub(/[&<>\u00A0]/,ESCAPE)}</#{name}>"
          elsif VOID.include? name.to_s
            line += "/>"
          else
            line += "></#{name}>"
          end

          if indent and width and (line.length > width or line.include? "\n")
            reflowed = IndentedTextNode.reflow(indent, line, width,
              options[:indent])
            line = reflowed.pop
            result.push *reflowed
          end
        end
      elsif CompactNode === self and not CompactNode === parent
        work = []
        walk(work, nil, options)
        width = options[:width]
        if width
          line += ">"
          work = work.join + "</#{name}>"
          if line.length + work.length <= width
            line += work
          else
            # split work into tokens with balanced <>
            tokens = work.split(' ')
            (tokens.length-1).downto(1)  do |i|
              if tokens[i].count('<') != tokens[i].count('>')
                tokens[i-1,2] = tokens[i-1] + ' ' + tokens[i]
              end
            end

            line += tokens.shift

            # add tokens to line, breaking when line length would exceed width
            tokens.each do |token|
              if line.length + token.length < width
                line += ' ' + token
              else
                result << line
                line = indent.to_s + options[:indent] + token
              end
            end
          end
        else
          line += ">#{work.join}</#{name}>"
        end
      else
        result <<  line+">#{options[:pre]}" if parent

        walk(result, indent, options) unless children.empty?

        line = "#{indent}#{options[:post]}</#{name}>"
      end

      result << line if parent
      result
    end

    def preserve_spaces?
      false
    end

    def root
      if parent
        parent.root
      else
        self
      end
    end

    def search(css)
      css = Node.parse_css_selector(css) if String === css

      matches = []
      if children
        children.each { |child| matches += child.search(css) if Node === child }
      end

      pattern = css.first

      if pattern[:id]
        return matches unless attrs and attrs[:id] == pattern[:id]
      end

      if pattern[:class]
        names = attrs ? attrs[:class].to_s.split(' ') : []
        return matches unless pattern[:class].all? {|name| names.include? name}
      end

      if pattern[:name]
        return matches unless name == pattern[:name]
      end

      if pattern[:attr]
        return matches unless attrs and pattern[:attr].all? do |k1, v1| 
          attrs.any? {|k2, v2| k1.to_s == k2.to_s and v1.to_s == v2.to_s}
        end
      end

      if css.length == 1
        matches << self
      else
        matches += search(css[1..-1])
      end
    end

    def at(css)
      search(css).first
    end

    # parse a subset of css_selectors
    def self.parse_css_selector(css)
      if css.include? ' '
        css.split(/\s+/).map {|token| parse_css_selector(token).first}
      else
        result = {}
        while css != ''
          if css =~/^([-\w]+)/
            result[:name] = $1
            css=css[$1.length..-1]
          elsif css =~/^#([-\w]+)/
            raise ArgumentError("duplicate id") if result[:id]
            result[:id] = $1
            css=css[$1.length+1..-1]
          elsif css =~/^\.([-\w]+)/
            result[:class] ||= []
            raise ArgumentError("duplicate class") if result[:class].include?  $1
            result[:class] << $1
            css=css[$1.length+1..-1]
          elsif css =~/^\[([-\w]+)=([-\w]+)\]/
            result[:attr] ||= {}
            raise ArgumentError("duplicate attribute") if result[:attr][$1]
            result[:attr][$1] = $2
            css=css[$1.length+$2.length+3..-1]
          elsif css =~/^\[([-\w]+)='([^']+)'\]/
            result[:attr] ||= {}
            raise ArgumentError("duplicate attribute") if result[:attr][$1]
            result[:attr][$1] = $2
            css=css[$1.length+$2.length+5..-1]
          elsif css =~/^\[([-\w]+)="([^"]+)"\]/
            result[:attr] ||= {}
            raise ArgumentError("duplicate attribute") if result[:attr][$1]
            result[:attr][$1] = $2
            css=css[$1.length+$2.length+5..-1]
          elsif css =~/^\*/
            css=css[1..-1]
          else
            raise ArgumentError("syntax error: #{css.inspect}")
          end
        end
        [result]
      end
    end
  end

  class CommentNode < Node
    def initialize(text)
      @text = text
    end

    def serialize(options, result, indent)
      result << "#{indent}<!-- #{@text} -->"
      result
    end
  end

  class DocTypeNode < Node
    attr_accessor :declare

    def initialize(*args)
      @declare = args.shift
      @name = args.shift
    end

    def serialize(options, result, indent)
      result << "<!#{@declare} #{@name.to_s}>"
      result
    end
  end

  class PreformattedNode < Node
    def preserve_spaces?
      true
    end
  end

  class CDATANode < PreformattedNode
    def self.normalize(data, indent='')
      data = data.sub(/\n\s*\Z/, '').sub(/\A\s*\n/, '')

      unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 0

      before  = ::Regexp.new('^'.ljust(unindent))
      node = @node
      data.gsub! before, indent
      data.gsub! /^#{indent}$/, '' if unindent == 0
      data
    end

    def serialize(options = {}, result = [], indent='')
      if @text and @text.include? "\n"
        tindent = (indent ? "#{indent}#{options[:indent]}" : indent)
        children.unshift CDATANode.normalize(@text, tindent).rstrip
        @text = nil
      end

      if @text and @text =~ /[<^>]/
        indent += options[:indent] if indent
        children.unshift @text.gsub(/^/, indent).gsub(/^ +$/,'').rstrip
        @text = nil
        super(options.merge(pre: pre, post: post), result, indent)
      elsif children && children.any? {|node| String===node && node =~ /[<^>]/}
        super(options.merge(pre: pre, post: post), result, indent)
      else
        super
      end
    end
  end

  class TextNode < Node
    def initialize(*args)
      super(nil, *args)
    end

    def serialize(options, result, indent)
      if options[:space] == :preserve
        result << @text.to_s.gsub(/[&<>\u00A0]/,ESCAPE)
      else
        result << @text.to_s.gsub(/[&<>\u00A0]/,ESCAPE).gsub(/\s+/, ' ')
      end
    end
  end

  class IndentedTextNode < TextNode
    def self.reflow(indent, line, width, next_indent)
      return [line] unless width and indent
      line = indent + line.gsub(/\s+/, ' ').strip
      indent += next_indent

      result = []
      while line.length > width
        split = line.rindex(' ', width)
        break if not split or split <= indent.to_s.length
        result << line[0...split]
        line = "#{indent}#{line[split+1..-1]}"
      end

      result << line
    end

    def serialize(options, result, indent)
      if indent
        text = CDATANode.normalize(@text, indent)
      else
        text = @text
      end

      result.push *IndentedTextNode.reflow(indent, 
        text.to_s.gsub(/[&<>\u00A0]/,ESCAPE), options[:width], '')
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

  module CompactNode; end

  module SpacedNode; end
end
