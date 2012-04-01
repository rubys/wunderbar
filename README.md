Wunderbar: Easy HTML5 applications
===

Wunderbar makes it easy to produce valid HTML5, wellformed XHTML, Unicode
(utf-8), consistently indented, readable applications.  This includes output
that conforms to the
[Polyglot](http://dev.w3.org/html5/html-xhtml-author-guide/) specification and
the emerging results from the [XML Error Recovery Community
Group](http://www.w3.org/community/xml-er/wiki/Main_Page).

Wunderbar is both inspired by, and builds upon Jim Weirich's 
[Builder](https://github.com/jimweirich/builder#readme), and provides 
the element id and class id syntax and based on the implementation from
[Markaby](http://markaby.rubyforge.org/).

Wunderbar's JSON support is inspired by David Heinemeier Hansson's
[jbuilder](https://github.com/rails/jbuilder).

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

Element with optional (omitted) attributes:

    _tr class: nil

Text:

    _ "hello"

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

    div.front do
    end

Id attributes shortcut (equivalent to id="search"):

    div.search! do
    end

Basic interface
---

A typical main program produces one or more of HTML, JSON, or plain text
output.  This is accomplished by providing one or more of the following:

    Wunderbar.html do
      code
    end
 
    Wunderbar.xhtml do
      code
    end
 
    Wunderbar.json do
      code
    end

    Wunderbar.text do
      code
    end
 
Arbitrary Ruby code can be placed in each.  To append to the output produced,
use the `_` methods described here.

Methods provided to Wunderbar.html
---

Invoking methods that start with a Unicode 
[low line](http://www.fileformat.info/info/unicode/char/5f/index.htm) 
character ("_") will generate a HTML tag.  As with builder on which this
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

The "`_`" method serves a number of purposes.  Calling it with a single argument
produces text nodes.  Inserting markup verbatim is done by "`_ << text`".  A
number of other convenience methods are defined:

* `_.post?`  -- was this invoked via HTTP POST?
* `_.system` -- invokes a shell command, captures stdin, stdout, and stderr
* `_.submit`: runs command (or block) as a deamon process

Access to all of the builder _defined_ methods (typically these end in an esclamation mark) and all of the Wunderbar module methods can be accessed in this way.  Examples:

* `_.tag! :foo`
* `_.error 'Log message'`

XHTML differs from HTML in the escaping of inline style and script elements.
XHTML will also fall back to HTML output unless the user agent indicates it
supports XHTML via the HTTP Accept header.

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

Globals provided
---
* `$cgi`   - Common Gateway Interface
* `$param` - Access to parameters (read-only OpenStruct like interface)
* `$env`  - Access to environment variables (read-only OpenStruct like interface)
* `$USER`  - Host user id
* `$HOME`  - Home directory
* `$SERVER`- Server name
* `SELF`   - Request URI
* `SELF?`  - Request URI with '?' appended (avoids spoiling the cache)
* `$HOME`   - user's home directory
* `$HOST`   - server host
* `$HTTP_GET`   - request is an HTTP GET
* `$HTTP_POST`  - request is an HTTP POST
* `$XHR_JSON`   - request is XmlHttpRequest for JSON
* `$XHTML`      - user agent accepts XHTML responses
* `$TEXT`       - user agent accepts plain text responses

Also, the following environment variables are set if they aren't already:

* `HOME`
* `HTTP_HOST`
* `LANG`
* `REMOTE_USER`

Finally, the (Ruby 1.9.x) default external and internal encodings are set to
UTF-8.  For Ruby 1.8, `$KCODE` is set to `U`

HTML methods
---
* `_head`: insert meta charset utf-8
* `_svg`: insert svg namespace
* `_math`: insert math namespace
* `_coffeescript`: convert [coffeescript](http://coffeescript.org/) to JS and insert script tag

Note that adding an exclamation mark to the end of the tag name disables this
behavior.

OpenStruct methods (for $params and $env)
---
* `untaint_if_match`: untaints value if it matches a regular expression

Builder extensions
---
* `indented_text!`: matches text indentation to markup
* `indented_data!`: useful for script and styles in HTML syntax
* `disable_indendation!`: temporarily disable insertion of whitespace
* `margin!`: insert blank lines between tags

Logging:
---
* `_.debug`: debug messages
* `_.info`: informational messages
* `_.warn`: warning messages
* `_.error`: error messages
* `_.fatal`: fatal error messages
* `_.log_level`=: set logging level (default: `:warn`)
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
