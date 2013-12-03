HelloWorld, part 2
===

This version of hello world is checked into github, so the first step
is to get a copy

    git clone https://github.com/rubys/wunderbar.git
    cd wunderbar

The demo that we are going to run next is
[helloworld.rb](https://github.com/rubys/wunderbar/blob/master/demo/helloworld.rb).
It isn't all that much more complicated.  It add a style, a paragraph, and a
form, and tiny bit of logic, in the form of an `if` statement.

```ruby

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
```

Run this directly, using a `--port` parameter, or install as CGI.  Visit the
page using a browser and you will see the header and a form.  This is because
name isn't set.

Enter a name and click submit, and you will see the page updated with a
friendly greeting.  As you can see, form parameters are mapped to
[ivars](http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Classes#Instance_Variables), and accessed by
prepending an `@` sign.

It isn't uncommon for Wunderbar applications to include both the view that
prompts for user input and the view that shows results.

HTML elements are formed by prepending an underscore to the element name.
HTML attributes are expressed as hashes.  Text is expressed as strings.  And
nesting is expressed via `do...end` blocks.

HTML is seamlessly interspersed with logic.  This also is frowned on with
other frameworks, and for good reason.  If your application is of any size,
this quickly becomes unmanageable.  But again, the competition for Wunderbar
isn't frameworks like Rails or even Sinatra, but scripts that are typically
run from the command line.  My philosophy is that small, self contained
applications are good; but once you start splitting things out, split
everything you can out.

This application demonstrates the use of Wunderbar as a better `ARGV`.
While it doesn't introduce anything new, the
[envdump](https://github.com/rubys/wunderbar/blob/master/demo/envdump.rb) demo
demonstrates the use of Wunderbar as a better `STDOUT`.

Next up, an application that is a bit more meaty.  But before moving on,
view source on the web page for either of these applications.  You will see
that everything is well formed and nicely indented.

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta charset="utf-8"/>
    <title>Greeter</title>
    <style type="text/css">
      input {display: block; margin: 2em}
    </style>
  </head>

  <body>
    <h1>Greeter</h1>
    <form method="post">
      <p>Please enter your name:</p>
      <input name="name"/>
      <input type="submit"/>
    </form>
  </body>
</html>
```
Now, onto the [chat](Chat.md) application.
