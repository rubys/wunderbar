# based on http://docs.angularjs.org/tutorial

require 'wunderbar/sinatra'
require 'wunderbar/angularjs'

get '/' do
  _html :index
end

get '/js/controllers.js' do
  _js :controllers
end
