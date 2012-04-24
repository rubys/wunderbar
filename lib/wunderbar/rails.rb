require 'active_support/core_ext'

module Wunderbar
  module Rails
    class HtmlHandler
      cattr_accessor :default_format
      self.default_format = Mime::HTML

      def self.call(template)
        %{
          compiled = Proc.new {#{template.source}}
          x = HtmlMarkup.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
          x.instance_eval &compiled
          x._.target!.join
        }.strip # take care to preserve line numbers in original source
      end
    end

    class JsonHandler
      cattr_accessor :default_format
      self.default_format = Mime::JSON

      def self.call(template)
        %{
          compiled = Proc.new {#{template.source}}
          x = Wunderbar::JsonBuilder.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
          x.instance_eval &compiled
          x.target!
        }.strip # take care to preserve line numbers in original source
      end
    end

    ActionView::Template.register_template_handler :_html, HtmlHandler
    ActionView::Template.register_template_handler :_json, JsonHandler
  end
end
