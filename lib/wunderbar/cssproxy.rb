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
      empty = (args.empty? or args == [''])
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

      args.first.chomp! if @node.name == :pre and ::String === args.first

      @node.parent.children.delete(@node)

      if block
        @node = @builder.tag! @node.name, *args, &block
      else
        @node = @builder.tag! @node.name, *args
      end

      if !block and empty
        self
      else
        @node
      end
    end
  end
end
