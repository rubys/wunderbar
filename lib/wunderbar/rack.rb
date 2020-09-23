require 'wunderbar'
require 'rack'
require 'rack/media_type'

module Wunderbar
  class RackApp
    # entry point for Rack
    def call(env)
      @_env = env
      @_request = Rack::Request.new(env)
      @_response = Rack::Response.new
      Wunderbar.logger = @_request.logger
      file = Wunderbar.files[env['PATH_INFO']]

      if file
        mime = file[:mime] ||
          Rack::Mime::MIME_TYPES[File.extname(env['PATH_INFO'])]
        @_response.set_header('Content-Type', mime) if mime
        @_response.write(file[:content] || file[:source].call)
      else
        Wunderbar::CGI.call(self)
      end
      @_response.finish
    end

    # redirect the output produced
    def out(headers,&block)
      status = headers.delete('status')
      @_response.status = status if status

      headers = Wunderbar::CGI.headers(headers)
      headers.each {|key, value| @_response[key] = value}

      @_response.write block.call unless @_request.head?
    end

    def env
      @_env
    end

    def params
      @_request.params
    end

    def request
      @_request
    end

    def response
      @_response
    end

    %w(delete get head options post put trace).each do |http_method|
      define_method "#{http_method}?" do
        @_env['REQUEST_METHOD'].to_s.downcase == http_method
      end
    end
  end
end

class Rack::Builder
  include Wunderbar::API

  def _app
    Wunderbar::RackApp.new
  end
end

