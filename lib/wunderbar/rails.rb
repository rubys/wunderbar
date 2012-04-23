require 'active_support/core_ext'

module Wunderbar
  module Rails
    class HtmlHandler
      cattr_accessor :default_format
      self.default_format = Mime::HTML

      def self.call(template)
        pre = %{
          x = HtmlMarkup.new(self);
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
