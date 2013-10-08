module Wunderbar
  # Class "lifted" from Markaby to store element options.  Methods called
  # against the CssProxy object are added as element classes or IDs.
  #
  # Modified to accept args for empty, non-void elements, and to capture and
  # restore indentation state.
  #
  # See the README for examples.
  class CssProxy
    def initialize(builder, sym, args)
      @builder = builder
      @sym     = sym
      @args    = args
      @attrs   = {}

      @builder.tag! sym, *args
    end

    def respond_to?(sym, include_private = false)
      include_private || !private_methods.map { |m| m.to_sym }.include?(sym.to_sym) ? true : false
    end

  private

    # Adds attributes to an element.  Bang methods set the :id attribute.
    # Other methods add to the :class attribute.
    def method_missing(id_or_class, *args, &block)
      if id_or_class.to_s =~ /(.*)!$/
        @attrs[:id] = $1
      else
        id = id_or_class
        @attrs[:class] = @attrs[:class] ? "#{@attrs[:class]} #{id}".strip : id
      end

      @attrs.merge! args.pop.to_hash  if args.last.respond_to? :to_hash
      @attrs.merge! @args.pop.to_hash if @args.last.respond_to? :to_hash

      # delete attrs with false/nil values; change true to attribute name
      @attrs.delete_if {|key, value| !value}
      @attrs.each {|key, value| @attrs[key]=key if value == true}

      args.push(@attrs)
      args = @args + args unless block or String === args.first

      if @sym == :pre
        args.first.chomp! if String === args.first and args.first.end_with? "\n"
      end

      if block
        @builder.tag! @sym, *args, &block
      else
        @builder.tag! @sym, *args
      end

      self
    end
  end
end
