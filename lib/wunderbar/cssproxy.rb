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

  private

    # Adds attributes to an element.  Bang methods set the :id attribute.
    # Other methods add to the :class attribute.
    def method_missing(id_or_class, *args, &block)
      empty = args.empty?
      attrs = @node.attrs

      if id_or_class.to_s =~ /(.*)!$/
        attrs[:id] = $1
      elsif attrs[:class]
        attrs[:class] = "#{attrs[:class]} #{id_or_class}"
      else
        attrs[:class] = id_or_class
      end

      attrs.merge! args.pop.to_hash if args.last.respond_to? :to_hash
      args.push(attrs)

      @node.parent.children.delete(@node)

      if empty and not block
        @builder.proxiable_tag! @node.name, *args
      elsif SpacedNode === @node
        @builder.__send__ "_#{@node.name}_", *args, &block
      else
        @builder.__send__ "_#{@node.name}", *args, &block
      end
    end
  end
end
