Wunderbar: Easy HTML5 applications
===

Wunderbar makes it easy to produce valid HTML5, wellformed XHTML, Unicode
(utf-8), consistently indented, readable applications.

Wunderbar was inspired by Jim Weirich's 
[Builder](https://github.com/jimweirich/builder#readme), and provides 
the element id and class id syntax and based on the implementation from
[Markaby](http://markaby.rubyforge.org/).

Wunderbar's JSON support is inspired by David Heinemeier Hansson's
[jbuilder](https://github.com/rails/jbuilder).

A [tutorial](https://github.com/rubys/wunderbar/blob/master/docs/Introduction1.md) is under development.

Additional functionality is provided by
[extensions](https://github.com/rubys/wunderbar/blob/master/docs/Extensions.md).

[![Build Status](https://travis-ci.org/rubys/wunderbar.svg)](https://travis-ci.org/rubys/wunderbar) 

Overview
---

The premise of Wunderbar is that output of various types are typically formed
by appending either a series of key/value pairs or simple values, and those
operations should be optimized for.  Appending a key/value pair is done via:

    _key value

... and appending a simple value is done thus:

    _ value

For HTML, key/value is used for element nodes, and simple values are used for
text nodes.  For JSON, key/value is used for Hashes and simple values are used
for arrays.  For text, simple values are output via puts, and key/value pairs
are not used.

Nesting is performed using blocks.

The underscore method, when passed no arguments, returns an object that can be
used to perform a number of special functions.  Some of those functions are
unique to the output method.  Others like logging methods are common.

The underscore method when passed multiple arguments or a combination of
arguments and a block may do other common functions, depending on the types of
the arguments passed.

Question mark, exclamation mark, and underscore suffixes to the method name
may modify the results.

Quick Start (HTML)
---

Simple element:

    _br

Nested elements:

    _div do
      _hr
    end

Element with text:

    _h1 "My weblog"

Element with attributes:

    _img src: '/img/logo.jpg', alt: 'site logo'

Element with both text and attributes:

    _a 'search', href: 'http://google.com'

Element with boolean attributes:

    _input 'Cheese', type: 'checkbox', name: 'cheese', checked: true

Element with boolean attributes (alternate form):

    _input 'Cheese', :checked, type: 'checkbox', name: 'cheese'

Element with optional (omitted) attributes:

    _tr class: nil

Text (markup characters are escaped):

    _ "<3"

Text (may contain markup):

    _{"<em>hello</em>!!!"}

Import of HTML/XML:

    _[Nokogiri::XML "<em>hello</em>"]

Mixed content (autospaced):

    _p do
      _ 'It is a'
      _em 'very'
      _ 'nice day.'
    end

Mixed content (space controlled):

    _p! do
      _ 'Source is on '
      _a 'github', href: 'https://github.com/'
      _ '.'
    end

Insert blank lines between rows in the HTML produced:

    _tbody do
      _tr_ do
        _td 1
      end
      _tr_ do
        _td 2
      end
      _tr_ do
        _td 3
      end
    end

Capture exceptions:

    _body? do
      raise NotImplementedError.new('page')
    end

Class attribute shortcut (equivalent to class="front"):

    _div.front do
    end

Id attributes shortcut (equivalent to id="search"):

    _div.search! do
    end

Complete lists/rows can be defined using arrays:

    _ul %w(apple orange pear)
    _ol %w(apple orange pear)
    _table do
      _tr %w(apple orange pear)
    end

Arbitrary iteration can be done over Enumerables:

    _dl.colors red: '#F00', green: '#0F0', blue: '#00F' do |color, hex|
      _dt color.to_s
      _dd hex
    end

Basic interface
---

A typical main program produces one or more of HTML, JSON, or plain text
output.  This is accomplished by providing one or more of the following:

    _html do
      code
    end
 
    _xhtml do
      code
    end
 
    _json do
      code
    end

    _text do
      code
    end
 
    _websocket do
      code
    end

Arbitrary Ruby code can be placed in each.  Form parameters are made available
as instance variables (e.g., `@name`).  Host environment (CGI, Rack, Sinatra)
values are accessible as methods of the `_` object: for example `_.headers`
(CGI), `_.set_cookie` (Rack), `_.redirect` (Sinatra).

To append to the output produced, use the `_` methods described below. 
Example applications are in the [tutorial](docs/README.md).

Methods provided to Wunderbar.html
---

Invoking methods that start with a Unicode 
[low line](http://www.fileformat.info/info/unicode/char/5f/index.htm) 
character ("_") will generate an HTML tag.  As with builder, on which this
library is based, these tags can have text content and attributes.  Tags can
also be nested.  Logic can be freely intermixed.

Wunderbar knows which HTML tags need to be explicitly closed with separate end
tags (example: `textarea`), and which should never be closed with separate end
tags (example: `br`).  It also takes care of HTML quoting and escaping of
arguments and text.

Suffixes after the tag name will modify the processing.

* `!`: turns off all special processing, including indenting
* `?`: adds code to rescue exceptions and produce tracebacks 
* `_`: adds extra blank lines between this tag and siblings

The "`_`" method serves a number of purposes.  Calling it with a single
argument inserts markup, respecting indendation.  Inserting markup without
regard to indendatation is done using "`_ << text`".  A number of other
convenience methods are defined:

* `_`: insert text with indentation matching the current output
* `_!`: insert text without indenting
* `_.post?`  -- was this invoked via HTTP POST?
* `_.system` -- invokes a shell command, captures stdin, stdout, and stderr
* `_.submit` -- runs command (or block) as a deamon process
* `_.xhtml?` -- output as XHTML?

Access to all of the builder _defined_ methods (typically these end in an esclamation mark) and all of the Wunderbar module methods can be accessed in this way.  Examples:

* `_.tag! :foo`: insert elements where the name can be dynamic
* `_.comment! "text"`: add a comment
* `_.error 'Log message'`: write a message to the server log

Underscores in element and attribute names are converted to dashes.  To
disable this behavior, express attribute names as strings and use the `_.tag!`
method for element names.

XHTML differs from HTML in the escaping of inline style and script elements.
XHTML will also fall back to HTML output unless the user agent indicates it
supports XHTML via the HTTP Accept header.

In addition to the default processing of elements, text, and attributes,
Wunderdar defines additional processing for the following:

* `_head`: insert meta charset utf-8
* `_svg`: insert svg namespace
* `_math`: insert math namespace
* `_coffeescript`: convert [coffeescript](http://coffeescript.org/) to JS and insert script tag

Note that adding an exclamation mark to the end of the tag name disables this
behavior.

If one of the attributes passed on the `_html` declaration is `:_width`, an
attempt will be made to reflow text in order to not exceed this line width.
This won't be done if it will affect what actually is displayed.

If none of the child elements for the `html` element are either `head` or
`body`, then these tags will be created for you, and the relevant children
will be moved to the appropriate section.  If the body contains a `h1`
element, and the `head` doesn't contain a `title`, a title element will be
created based on the text supplied to the first `h1` element.

Methods provided to Wunderbar.json
---

Common operations are to return a Hash or an Array of values.  Hashes are
a series of name/value pairs, and Arrays are a series of values.

``` ruby
Wunderbar.json do
  _content format_content(@message.content)
  _ @message, :created_at, :updated_at 

  _author do
    _name @message.creator.name.familiar
    _email_address @message.creator.email_address_with_name
    _url url_for(@message.creator, format: :json)
  end

  if current_user.admin?
    _visitors calculate_visitors(@message)
  end

  _comments @message.comments, :content, :created_at
  
  _attachments @message.attachments do |attachment|
    _filename attachment.filename
    _url url_for(attachment)
  end
end
```

Invoking methods that start with a Unicode 
[low line](http://www.fileformat.info/info/unicode/char/5f/index.htm) 
character ("_") will add a key/value pair to that hash.  Hashes can
also be nested.  Logic can be freely intermixed.

The "`_`" method serves a number of purposes.

* calling it with multiple arguments will cause the first argument to be
treated as the object, and the remainder as the attributes to be extracted
    * Example: `_ File.stat('foo'), :mtime, :size, :mode`

* calling it with a single Enumerable object and a block will cause an array
to be returned based on mapping each objection from the enumeration against
the block
   * Example: `_([1,2,3]) {|n| n*n}`

* arrays can be also be built using the `_` method:

        _ 1
        _ 2

The `_` method returns a proxy to the object being constructed.  This is often
handy when called with no arguments.  Examples:

        _.sort!
        _['foo'] = 'bar'

Methods provided to Wunderbar.text
---

Appending to the output stream is done using the `_` method, which is
equivalent to `puts`.  The `_` method returns an object which proxies the
output stream, which provides access to other useful methods, for example:

        _.print 'foo'
        _.printf "Hello %s!\n", 'world'

Methods provided to Wunderbar.websocket
---

WebSocket support requires `em-websocket` to be installed.

A web socket is a bidrectional channel.  `_.send` or `_.push` can be used to
send arbitrary strings.  More commonly, the JSON array methods described above
can be all be used, the important difference is that the individual entries
are sent individually and as they are produced.

`_.recv` or `_.pop` can be used to receive arbitrary strings.  More commonly,
`_.subscribe` is used to register a block that is used as a callback.

`_.system` will run an arbitrary command.  Lines of output are sent across the
websocket as they are received as JSON encoded hashes with two values: `type`
is one of `stdin`, `stdout` or `stderr`; and `line` which contains the line
itself.  If the command is an array, the elements of the array will be escaped
as Shell command arguments.  Nested arrays may be used to hide elements from
the echoing of the command to stdin.  Nil values are omitted.

Options to `_websocket` are provided as a hash:  

   * `:port` will chose a port number, with the default being that an
   available one is picked for you.
   * `:sync` set to `false` will cause the WebSocket server to be run as a 
   daemon process.  This defaults to `true` when run from the command line and
   to `false` when run as CGI.
   * `buffer_limit` will limit the amount of entries retained and sent to
   new clients on open requests.  Default is `1`.  A value of zero will disable
   buffering.  A value of `nil` will result in unlimited buffering.  Note:
   buffering is effectively unlimited until the first client connects.


Secure by default
---

Wunderbar will properly escape all HTML and JSON output, eliminating problems
of HTML or JavaScript injection.  This includes calls to `_` to insert text
directly.  Unless `nokogiri` was previously required (see [optional
dependencies](#optional-dependencies) below), calls to insert markup
(`_{...}`) will escape the markup if the input is `tainted` and not explicitly
marked as `html_safe?` (when using Rails).

A special feature that effectively is only available in the Rails environment:
if the first argument to call that creates an element is `html_safe?`, then
that argument will be treated as a markup instead of as text.  This allows one
to make calls like `_td link_to...` without placing the call to `link_to` in a
block.

Globals provided
---
* `$USER`   - Host user id
* `$PASSWORD` - Host password (if CGI and HTTP_AUTHORIZATION is passed through)
* `$HOME`   - Home directory
* `$SERVER` - Server name
* `$HOME`   - user's home directory
* `$HOST`   - server host

Also, the following environment variables are set if they aren't already:

* `HOME`
* `HTTP_HOST`
* `LANG`
* `REMOTE_USER`

Finally, the default external and internal encodings are set to UTF-8.

Logging
---
* `_.debug`: debug messages
* `_.info`: informational messages
* `_.warn`: warning messages
* `_.error`: error messages
* `_.fatal`: fatal error messages
* `_.log_level`=: set logging level (default: `:warn`)
* `_.default_log_level`=: set, but don't override, log level
* `_.logger`: return [Logger](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html) instance

Command line options
---
When run from the command line, CGI name=value pairs can be specified.
Additionally, the following options are supported:

* `--get`:  HTML (HTTP GET) output is expected
* `--post`: HTML (HTTP POST) output is expected
* `--json`: JSON (XML HTTP Request) output is expected
* `--html`: force HTML output
* `--prompt` or `--offline`: prompt for key/value pairs using stdin
* `--debug`, `--info`, `--warn`, `--error`, `--fatal`: set log level
* `--install=`path: produce an suexec-callable wrapper script
* `--rescue` or `--backtrace` cause wrapper script to capture errors

Optional dependencies
---

The following gems are needed based on what functions you use:

* `em-websocket` is required by `wunderbar/websocket`
* `kramdown` is required by `wunderbar/markdown`
* `ruby2js` adds support for scripts written as blocks
* `sourcify` is required by `wunderbar/opal`

The following gems are required by extensions of the same name:

* `coderay` - syntax highlighting
* `opal` - ruby to javascript compiler
* `rack` - webserver interface
* `rails` - web application framework
* `sinatra` - DSL for creating web applications

The following gems, if installed, will produce cleaner and prettier output:

* `nokogiri` cleans up HTML fragments inserted via `<<` and `_{}`.
* `nokogumbo` also cleans up HTML fragments inserted via `<<` and `_{}`.  If
  this gem is available, it will be preferred over direct usage of `nokogiri`.
* `escape` prettier quoting of `system` commands
* `sanitize` will remove unsafe markup from tainted input

Related efforts
---
* [Builder](https://github.com/jimweirich/builder#readme)
* [JBuilder](https://github.com/rails/jbuilder)
* [Markaby](http://markaby.rubyforge.org/)
* [Nokogiri::HTML::Builder](http://nokogiri.org/Nokogiri/HTML/Builder.html)
* [Tagz](https://github.com/ahoward/tagz)
