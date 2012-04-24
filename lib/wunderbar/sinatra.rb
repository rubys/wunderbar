require 'sinatra'
require 'digest/md5'
require 'nokogiri'

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
          output = new(&Proc.new {}).evaluate(scope, {}, &block)
        else
          output = scope.send :render, template, *args
        end
        scope.etag Digest::MD5.hexdigest(output)
        output
      end

    private

      def _evaluate(builder, scope, locals, &block)
        builder.instance_eval do
          scope.params.merge(locals).each do |key,value|
            value = value.first if ::Array === value
            instance_variable_set "@#{key}", value if key =~ /^[a-z]\w+$/
          end
        end

        if not block
          builder.instance_eval(data.untaint, eval_file)
        elsif not data
          builder.instance_eval(&block)
        else
          context = builder.get_binding do
            builder.instance_eval {_? block.call}
          end
          context.eval(data.untaint, eval_file)
        end
      end

      def _evaluate_safely(*args, &block)
        if Wunderbar.safe? and $SAFE==0
          Proc.new { $SAFE=1; _evaluate(*args, &block) }.call
        else
          _evaluate(*args, &block)
        end
      end
    end

    class Html < Base
      self.default_mime_type = 'text/html'

      def evaluate(scope, locals, &block)
        builder = HtmlMarkup.new(scope)
        begin
          _evaluate_safely(builder, scope, locals, &block)
        rescue Exception => exception
          scope.response.status = 500
          builder.clear!
          builder.html do
            _head do
              _title 'Internal Server Error'
            end
            _body do
              _h1 'Internal Server Error'
              _exception exception
            end
          end
        end
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
        begin
          _evaluate_safely(builder, scope, locals, &block)
        rescue Exception => exception
          scope.content_type self.class.default_mime_type, :charset => 'utf-8'
          scope.response.status = 500
          builder._exception exception
        end
        builder.target!
      end
    end

    class Text < Base
      self.default_mime_type = 'text/plain'

      def evaluate(scope, locals, &block)
        builder = TextBuilder.new(scope)
        begin
          _evaluate_safely(builder, scope, locals, &block)
          scope.response.status = 404 if builder.target!.empty?
        rescue Exception => exception
          scope.headers['Content-Type'] = self.class.default_mime_type
          scope.response.status = 500
          builder._exception exception
        end
        builder.target!
      end
    end
  end

  module SinatraHelpers
    def _html(*args, &block)
      if block
        Wunderbar::Template::Html.evaluate('_html', self) do
          _html(*args) { instance_eval &block }
        end
      else
        Wunderbar::Template::Html.evaluate('_html', self, *args)
      end
    end

    def _xhtml(*args, &block)
      if env['HTTP_ACCEPT'] and not env['HTTP_ACCEPT'].include? 'xhtml'
        return _html(*args, &block)
      end

      if block
        Wunderbar::Template::Xhtml.evaluate('_xhtml', self) do
          _xhtml(*args) { instance_eval &block }
        end
      else
        Wunderbar::Template::Xhtml.evaluate('_xhtml', self, *args)
      end
    end

    def _json(*args, &block)
      Wunderbar::Template::Json.evaluate('_json', self, *args, &block)
    end

    def _text(*args, &block)
      Wunderbar::Template::Text.evaluate('_text', self, *args, &block)
    end
  end
end

Tilt.register '_html',  Wunderbar::Template::Html
Tilt.register '_xhtml', Wunderbar::Template::Xhtml
Tilt.register '_json',  Wunderbar::Template::Json
Tilt.register '_text',  Wunderbar::Template::Text

helpers Wunderbar::SinatraHelpers
