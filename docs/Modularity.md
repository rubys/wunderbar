Modularity
===

At this point, some of the demos are starting to get lengthy.  With CGI, an
application that spans multiple pages can be put into separate files.  Running
a server per page, however, quickly becomes unwieldly.  Wunderbar provides a
few strategies for splitting an application up.

Sinatra
---

The helloworld demo application described previously can be split into
separate parts by action using Sinatra.  The result is the [Sinatra
demo](https://github.com/rubys/wunderbar/blob/master/demo/hellosinatra.rb)
contains the result:

```ruby
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
```

To run this, start by installing Sinatra:

    sudo gem install sinatra

Then run the program using `ruby hellosinatra.rb`

This file could be split into multiple files where the base file requires the
other ones.  More commonly, one can place the `_html` parts into a `view`
directory and pulled in when needed.  Simply name the files with `._html`,
`._json` or `._text` extensions as appropriate.

Polymer
---

The [Polymer project](http://www.polymer-project.org/) includes
[polyfill](http://en.wikipedia.org/wiki/Polyfill)
implementing [Web Components](http://www.w3.org/TR/components-intro/)
as well as additional libraries build on top of this functionality.

One feature of Web Components is templates that you can import.  An example:

```ruby
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
```

Templates
---

Should templates be all that you need, Wunderbar supports server side
templates:

```ruby
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
```

Note that Wunderbar templates can reference values provided as attributes and
can yield back to the caller to get additional content.
