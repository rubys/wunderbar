module Wunderbar
  # Class inspired by Markaby to store element options.  Methods called
  # against the CssProxy object are added as element classes or IDs.
  #
  # See the README for examples.
  class CssProxy < BasicObject
    def initialize(builder, node)
      @builder = builder
      @node = node
    end

    def node?
      @node
    end

  private

    # Adds attributes to an element.  Bang methods set the :id attribute.
    # Other methods add to the :class attribute.
    def method_missing(id_or_class, *args, &block)
      empty = args.empty?
      attrs = @node.attrs
      id_or_class = id_or_class.to_s.gsub('_', '-')

      if id_or_class =~ /(.*)!$/
        attrs[:id] = $1
      elsif attrs[:class]
        attrs[:class] = "#{attrs[:class]} #{id_or_class}"
      else
        attrs[:class] = id_or_class
      end

      iterable = block && block.arity != 0
      if args.last.respond_to? :to_hash and not iterable
        hash = args.pop.to_hash 
        if attrs[:class] and hash[:class]
          hash[:class] = "#{attrs[:class]} #{hash[:class]}"
       end
        attrs.merge! hash
      end
      args.push(attrs)

      @node.parent.children.delete(@node)

      if empty and not block
        proxy = @builder.proxiable_tag! @node.name, *args
        class << proxy.node?; include SpacedNode; end  if SpacedNode  === @node
        class << proxy.node?; include CompactNode; end if CompactNode === @node
        proxy
      else
        name = @node.name.to_s.gsub('-', '_')
        if CompactNode === @node and @node.name != :pre
          if SpacedNode === @node
            @builder.__send__ "_#{name}_!", *args, &block
          else
            @builder.__send__ "_#{name}!", *args, &block
          end
        elsif SpacedNode === @node
          @builder.__send__ "_#{name}_", *args, &block
        else
          @builder.__send__ "_#{name}", *args, &block
        end
      end
    end
  end
end
