Chat Server
===

This application has three parts.  A back end server that maintains a list
of clients and communicates with each.  A web server that produces HTML
to be consumed by clients.  And as many clients as you wish, either in the
form of multiple browsers or multiple tabs in one browser, or any combination
thereof.

The heavy lifting for this is provided by
[WebSockets](http://www.websocket.org/), which is implemented on the client
by the latest version of all major browsers, and implemented on the server by
[em-websocket](http://rubygems.org/gems/em-websocket).

WebSocket support isn't included by default with Wunderbar, but must be pulled
in explicitly.  And when you do so, you will find that you have additional
dependencies.  This demo also require a library that converts Ruby to
JavaScript, so lets install both at the same time:

    sudo gem install em-websocket ruby2js

With that in place, lets look at the
[chat demo](https://github.com/rubys/wunderbar/blob/master/demo/chat.rb).

```ruby
require 'wunderbar/jquery'
require 'wunderbar/websocket'

PORT = 8080

if ENV['SERVER_PORT']

  _html do
    # ...
  end

else

  # echo server
  # ...

end
```

The first two executable lines pull in jquery and websocket respectively.
Next the PORT number which is used to communicate between the backend server
and the web clients is defined.  Finally, there is an `if` statement to
distinguish between the code used to implement the web interface and the back
end server based on whether the `SERVER_PORT` 
[environment variable](http://www.cgi101.com/book/ch3/text.html) is set.

Next onto the HTML:

```ruby
_html do
  _style_ %{
    textarea {width: 100%; height: 10em}
    #error {color: red; margin-top: 1em}
    #error pre {margin: 0}
  }

  _h1_ "Chat on port # #{PORT}"
  _textarea
  _div.status!
  _div.error!

  /* ... */
_end
```

A few new features are used in the HTML.  Element names that not only start
with but also end with underscores result in whitespace around the element in
the resulting HTML.  Element names that end in a dot followed by a name
followed by an exclamation point cause an `id` attribute to be added to the
element.  This syntax was inspired by
[markaby](http://markaby.rubyforge.org/files/README.html).  Not used by this
demo, but class attributes can also be defined in the same way, simply omit
the exclamation point.

The most interesting part of the HTML in this demo is the `script` element.
The first line creates a WebSocket using the value of `@socket`, an instance
variable defined outside of the script and referenced inside.

```ruby
@socket = "ws://#{env['HTTP_HOST']}:#{PORT}/"

_script_ do
  ws = WebSocket.new(@socket)
  ~'textarea'.on(:input) { ws.send(~this.val) }

end
```

As `$` is not a valid method name in Ruby, Wunderbar maps `~` to `jQuery`.
The next line makes two calls to jQuery via `~'textarea'` and `~this`, with
the result being that whenever any input is made inside the text area, a call
to the `ws.send` function is made with the value of that text area.

Finally, two event handlers are defined.

```ruby
ws.onmessage = proc do |evt|
  data = JSON.parse(evt.data)

  case data.type
  when 'status'
    ~'#status'.text = data.line
  when 'stderr'
    ~"#error".append(~'<pre>').text = data.line
  else
    ~'textarea'.val = data.line
  end
end

ws.onclose = proc do
  ~'textarea'.readonly = true
  ~'#status'.text = 'chat terminated'
end
```

The first event handler handles messages from the server, and updates one of
three elements based on the content of the message.  The second event handler
handles notification of the server closing down, and changes the textarea
field to readonly and updates the status line.  JQuery is used throughout.

The most notable feature of the script is that it is written entirely in Ruby.
A description of the jQuery specific transformations can be found in the
comments for the [ruby2js jquery filter](https://github.com/rubys/ruby2js/blob/master/lib/ruby2js/filter/jquery.rb).

After the `else` is the back end server logic.  As mentioned before, the heavy
lifting is done by [EventMachine](http://rubyeventmachine.com/).  All
Wunderbar does is provide a thin wrapper over this library.  Three event
handlers are defined, and inside those handlers output is defined using hashes
preceded by -- as you by now might expect -- an underscore.  Such output is
marshalled as JSON which is readily consumable by the client web browser
processes.

```ruby
_.onopen do
  count += 1
  _ type: 'status', line: "waiting for others to join" if count == 1
  _ type: 'status', line: "#{count} members in chat" if count > 1
  _ type: 'msg', line: content
end

_.subscribe do |msg|
  puts msg
  _ type: 'msg', line: msg
  content = msg
end

_.onclose do
  count -= 1
  _ type: 'status', line: "waiting for others to join" if count == 1
  _ type: 'status', line: "#{count} members in chat" if count > 1
end
```

Finally, a loop is defined which will shut down after 10 minutes of not
finding a client or within one minute after the last client exits.

To run this, start by launching the back end process:

    ruby chat.rb

Next, in a separate window, launch the web server:

    ruby chat.rb --port=8000

Finally, in a web browser navigate to
[http://localhost:8000/](http://localhost:8000/).  Type a few characters in
the textarea and then take a look at the window running the back end process
-- you should see your input echoed there.  After you do this, launch a second
and third browser window and navigate to the same page.  In any window, change
the value of the textarea and see it instantly update in every browser window
and echoed on the window containing the back end server.

Experiment with closing windows and opening new ones, and even shutting down
the back end server.

Before moving on, view source on the web pages in your browser.  What you will
see is well formed and consistently indented content.  Your script has been
converted from idiomatic Ruby into clean, idiomatic JavaScript.

```javascript
ws.onmessage = function(evt) {
  var data = JSON.parse(evt.data);

  switch (data.type) {
  case "status":
    $("#status").text(data.line);
    break;

  case "stderr":
    $("#error").append($("<pre>")).text(data.line);
    break;

  default:
    $("textarea").val(data.line)
  }
}
```

Next up, an [Angular.js demo](AngularJS.md).
