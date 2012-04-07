require 'tilt/template'

module Wunderbar
  # Tilt template implementation
  module Template
    class Base < Tilt::Template
      def self.engine_initialized?
        defined? ::Wunderbar
      end

      def initialize_engine
        require_template_library 'wunderbar'
      end

      def prepare
      end

      def precompiled_template(locals)
        raise NotImplementedError.new("dynamic only")
      end

      def precompiled_preamble(locals)
        raise NotImplementedError.new("dynamic only")
      end

      def precompiled_postamble(locals)
        raise NotImplementedError.new("dynamic only")
      end

      def self.evaluate(template, scope, *args, &block)
        scope.content_type default_mime_type
        if block
          new(&Proc.new {}).evaluate(scope, {}, &block)
        else
          scope.send :render, template, *args
        end
      end

    private

      def _evaluate(builder, scope, locals, &block)
        builder.instance_eval do
          scope.params.merge(locals).each do |key,value|
            value = value.first if ::Array === value
            instance_variable_set "@#{key}", value if key =~ /^[a-z]\w+$/
          end
        end
        if block
          builder.instance_eval(&block)
        else
          builder.instance_eval(data, eval_file)
        end
      end
    end

    class Html < Base
      self.default_mime_type = 'text/html'

      def evaluate(scope, locals, &block)
        builder = HtmlMarkup.new(scope)
        _evaluate(builder, scope, locals, &block)
        builder._.target!.join
      end
    end

    class Xhtml < Html
      self.default_mime_type = 'application/xhtml+xml'
    end

    class Json < Base
      self.default_mime_type = 'application/json'

      def evaluate(scope, locals, &block)
        builder = JsonBuilder.new(scope)
        _evaluate(builder, scope, locals)
        builder.target!
      end
    end

    class Text < Base
      self.default_mime_type = 'text/plain'

      def evaluate(scope, locals, &block)
        builder = JsonBuilder.new(scope)
        _evaluate(builder, scope, locals)
        builder.target!
      end
    end
  end
end

