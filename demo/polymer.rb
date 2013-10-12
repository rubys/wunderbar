require 'wunderbar/polymer'
require 'wunderbar/sinatra'

get '/' do
  _html do
    _title 'polymer demo'
    _link rel: 'import', href: 'polymer-widget.html'
    _polymer_widget
  end
end

get '/polymer-widget.html' do
  _polymer_element name: 'polymer-widget' do
    _template_ do
      _h1 'Hello world!'
      _p 'It worked!'
    end
    _script 'Polymer("polymer-widget");'
  end
end
