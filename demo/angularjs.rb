# based on http://docs.angularjs.org/tutorial

require 'wunderbar/sinatra'
require 'wunderbar/angularjs/route'
require 'wunderbar/angularjs/resource'

set :views, File.dirname(__FILE__)

get '/' do
  _html :'views/index'
end

get '/partials/:_name.html' do
  _html :"partials/#{params[:_name]}"
  end

get '/js/:_name.js' do
  _js :"js/#{params[:_name]}"
end

