require 'active_support/core_ext'

module Wunderbar
  module Rails
    class HelperProxy < HtmlMarkup
      def method_missing(symbol, *args, &block)
        if @_scope.respond_to? symbol
          if @_scope.method(symbol).owner.parents.include?  ActionView::Helpers
            return _import! @_scope.__send__(symbol, *args, &block)
          end
        elsif @_scope.helpers.instance_methods.include? symbol
          return _import! @_scope.__send__(symbol, *args, &block)
        end
        super
      end
    end

    class HtmlHandler
      cattr_accessor :default_format
      self.default_format = Mime::HTML

      def self.call(template)
        pre = %{
          x = Wunderbar::Rails::HelperProxy.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
        }.strip.gsub(/\s+/, ' ')

        post ="x._.target!.join"

        # take care to preserve line numbers in original source
        "#{pre}; x.instance_eval { #{template.source} }; #{post}"
      end
    end

    class JsonHandler
      cattr_accessor :default_format
      self.default_format = Mime::JSON

      def self.call(template)
        pre = %{
          x = Wunderbar::JsonBuilder.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
        }.strip.gsub(/\s+/, ' ')

        post ="x.target!"

        # take care to preserve line numbers in original source
        "#{pre}; x.instance_eval { #{template.source} }; #{post}"
      end
    end

    ActionView::Template.register_template_handler :_html, HtmlHandler
    ActionView::Template.register_template_handler :_json, JsonHandler
  end
end
