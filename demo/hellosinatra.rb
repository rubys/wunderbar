require 'sinatra'
require 'wunderbar'

get '/' do
  _html do
    _head_ do
      _title 'Greeter'
      _style %{
        input {display: block; margin: 2em}
      }
    end

    _body? do
      _form method: 'post' do
        _p 'Please enter your name:'
        _input name: 'name'
        _input type: 'submit'
      end
    end
  end
end

post '/' do
  _html do
    _head_ do
      _title 'Greeter'
    end

    _body? do
      _p "Hello #{@name}!"
    end
  end
end
