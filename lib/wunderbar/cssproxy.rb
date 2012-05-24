module Wunderbar
  # Class "lifted" from Markaby to store element options.  Methods called
  # against the CssProxy object are added as element classes or IDs.
  #
  # Modified to accept args for empty, non-void elements, and to capture and
  # restore indentation state.
  #
  # See the README for examples.
  class CssProxy
    def initialize(builder, stream, sym, args)
      @builder = builder
      @indent  = builder.indentation_state!
      @stream  = stream
      @sym     = sym
      @args    = args
      @attrs   = {}

      @original_stream_length = @stream.length

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

      args.push(@attrs)
      args = @args + args unless block or String === args.first

      while @stream.length > @original_stream_length
        @stream.pop
      end

      begin
        indent = @builder.indentation_state! @indent

        if block
          @builder.tag! @sym, *args, &block
        else
          @builder.tag! @sym, *args
        end
      ensure
        @builder.indentation_state! indent
      end

      self
    end
  end
end
