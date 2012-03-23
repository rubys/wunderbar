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
.

Quick Start
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
      expression
    end

    Wunderbar.text do
      code
    end
 
Arbitrary Ruby code can be placed in each.  For html, use the `_` methods described here.  For json, the results (typically a hash or array) are converted to JSON.  For text, use `puts` and `print` statements to produce the desired results.

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

CGI methods (deprecated?)
---
* `json`    - produce JSON output using the block specified
* `json!`   - produce JSON output using the block specified and exit
* `html`    - produce HTML output using the block specified
* `html!`   - produce HTML output using the block specified and exit
* `post`    - execute block only if method is POST
* `post!`   - if POST, produce HTML output using the block specified and exit

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
