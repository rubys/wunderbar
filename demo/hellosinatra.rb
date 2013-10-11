require 'wunderbar/sinatra'

get '/' do
  _html do
    _title 'Greeter'
    _style "input {display: block; margin: 2em}"

    _form method: 'post' do
      _p 'Please enter your name:'
      _input name: 'name'
      _input type: 'submit'
    end
  end
end

post '/' do
  _html do
    _title 'Greeter'
    _p "Hello #{@name}!"
  end
end
