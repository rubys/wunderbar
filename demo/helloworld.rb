require 'wunderbar'

_html do
  _head_ do
    _title 'Greeter'
    _style %{
      input {display: block; margin: 2em}
    }
  end

  _body? do
    if @name
      _p "Hello #{@name}!"
    else
      _form method: 'post' do
        _p 'Please enter your name:'
        _input name: 'name'
        _input type: 'submit'
      end
    end
  end
end
