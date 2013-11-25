require 'wunderbar'
require 'rack'

module Wunderbar
  class RackApp
    # entry point for Rack
    def call(env)
      @_env = env
      @_request = Rack::Request.new(env)
      @_response = Rack::Response.new
      Wunderbar.logger = @_request.logger
      if Wunderbar.safe? and $SAFE==0
        Proc.new { $SAFE=1; Wunderbar::CGI.call(self) }.call
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
  end
end

class Rack::Builder
  include Wunderbar::API

  def _app
    Wunderbar::RackApp.new
  end
end

