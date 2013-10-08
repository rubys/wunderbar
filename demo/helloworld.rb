# view source!

require 'wunderbar'

_html do
  _style %{
    input {display: block; margin: 2em}
  }

  _h1 'Greeter'

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
