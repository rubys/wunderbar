require 'wunderbar'

#
# server side template
#
_template :website_layout do
  _style %{
    h1 {background-color: blue; color: yellow; padding: 0.3em 1em}
  }
  _h1_ @title
  _div.content do
    _yield
  end
end

#
# making use of a server side template
#
_html do
  _website_layout title: 'Template demo' do
    _p 'It worked!'
  end
end
