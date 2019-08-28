require 'active_support/core_ext'
require 'action_view'

module Wunderbar
  module Rails
    class HtmlHandler
      cattr_accessor :default_format
      self.default_format = Mime[:html]

      def self.call(template, source)
        %{
          compiled = Proc.new {#{template.source}}
          x = Wunderbar::HtmlMarkup.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
          x.instance_eval(&compiled)
          x._.target!
        }.strip # take care to preserve line numbers in original source
      end
    end

    class JsonHandler
      cattr_accessor :default_format
      self.default_format = Mime[:json]

      def self.call(template, source)
        %{
          compiled = Proc.new {#{template.source}}
          x = Wunderbar::JsonBuilder.new(self);
          instance_variables.each do |var|
            x.instance_variable_set var, instance_variable_get(var)
          end
          x.instance_eval(&compiled)
          x.target!
        }.strip # take care to preserve line numbers in original source
      end
    end

    ActionView::Template.register_template_handler :_html, HtmlHandler
    ActionView::Template.register_template_handler :_json, JsonHandler
  end
end
