Extensions
===

Wunderbar is extensible in a number of directions.  Extensions may be as
simple as adding a few `<script>` and/or `<link>` statements to the `<head>`
section of the resulting page using
[assets](https://github.com/rubys/wunderbar/blob/master/lib/wunderbar/asset.rb).
Or declaratively using
[templates](https://github.com/rubys/wunderbar/blob/master/docs/Modularity.md#templates).
Or programmatically by extending
[Wunderbar::HtmlMarkup](http://rubydoc.info/gems/wunderbar/0.19.0/Wunderbar/HtmlMarkup).

While extensions may be defined outside of Wunderbar; Wunderbar includes a
number of extensions.  Including an extension is generally as simple as
<code>require 'wunderbar/<em>extension-name</em>'</code>.

Following is a brief description of each of the extensions included with
Wunderbar.

coderay
---

This adds a `_coderay` macro that accepts a language (as a symbol), a String,
and an optional hash.  The string is passed through
[coderay](http://coderay.rubychan.de/) and the result embedded in a `pre`
element.  If attributes are provided, they are added to the `pre` element.

coffeescript
---

This extension adds a `_coffeescript` macro that accepts a string.  The string
is converted to Javascript and the tag is replace with a `script`.

job-control
---

Adds a `_.submit` method which daemonizes a command or block.  The websocket
extension makes use of this.

jquery
---

This extension adds a link statement to the jquery library.  If you require
`jquery/stupidtable` instead, you get both libraries.

If Ruby2JS is available, then the jquery script filters are also loaded.

Demos:
* [chat.rb](https://github.com/rubys/wunderbar/blob/master/demo/chat.rb)
* [diskusage.rb](https://github.com/rubys/wunderbar/blob/master/demo/diskusage.rb)
* [opal-jquery.rb](https://github.com/rubys/wunderbar/blob/master/demo/opal-jquery.rb)
* [wiki.rb](https://github.com/rubys/wunderbar/blob/master/demo/wiki.rb)

markdown
---

This extension introduces a `_markdown` macro that takes a string and
interprets it as [markdown](http://daringfireball.net/projects/markdown/),
and adds the HTML fragment produced into the current document.

This extension requires [kramdown](http://rubygems.org/gems/kramdown) and
[nokogiri](http://rubygems.org/gems/nokogiri).

Demo:
* [wiki.rb](https://github.com/rubys/wunderbar/blob/master/demo/wiki.rb)

opal
---

Converts blocks passed to `_script` from Ruby to JavaScript using
[Opal](http://opalrb.org/).  This functionality is not compatible with the
script extension which does something similar using Ruby2JS.

Additional Opal functionality can be obtained if you add 
`require opal/browser` or `require opal/jquery`.

Requires [sourcify](http://rubygems.org/gems/sourcify),
[opal](http://rubygems.org/gems/opal) (and optionally,
[opal-jquery](http://rubygems.org/gems/opal-jquery) or opal-browser, once it
becomes available.

Demos:
* [opal-browser.rb](https://github.com/rubys/wunderbar/blob/master/demo/opal-browser.rb)
* [opal-jquery.rb](https://github.com/rubys/wunderbar/blob/master/demo/opal-jquery.rb)

polymer
---

Adds `_polymer_element` to the list of data types supported by Wunderbar.
If used with Sinatra, will define the appropriate helpers too.

Demo:
* [polymer.rb](https://github.com/rubys/wunderbar/blob/master/demo/polymer.rb)

rack
---

Deploys a wunderbar application as a Rack application, enabling integration
with a wide (and growing) list of 
[Rack servers](http://rack.rubyforge.org/doc/).

Demo:
* [config.ru](https://github.com/rubys/wunderbar/blob/master/demo/config.ru)

script
---

Converts blocks passed to `_script` from Ruby to JavaScript.  If Sinatra is in
use, also defines a `_js` helper as well as defining a template for files with
an extension of `_js`.

Instance variables defined in the calling script are made available to the
script.  As such values are converted to JavaScript, they are limited to
Integers, Floats, Strings, Symbols, and Arrays or Hashes containing only these
types.

Requires the [ruby2js](http://rubygems.org/gems/ruby2js/) gem to be installed.

If the [binding_of_caller](https://rubygems.org/gems/binding_of_caller) gem is
available (i.e., was previously required), then local variables of the caller
are also made available.

sinatra
---

Adds helpers and templates enabling Wunderbar to be used with Sinatra.
`_html`, `_json`, `_text`, and `_template` may be used directly inside Sinatra
scripts using constructs such as `_html do...end`, or in views using 
`_html :viewName`.  Extensions for Wunderbar views are `_html`, `_json`,
etcetera.

Demos:
* [hellosinatra](https://github.com/rubys/wunderbar/blob/master/demo/hellosinatra.rb)

websocket
---

This extension defines a thin wrapper over Event Machine's web socket
interface.  Requires the [em-websocket](http://rubygems.org/gems/em-websocket)
gem to be installed.

Demos:
* [chat](https://github.com/rubys/wunderbar/blob/master/demo/chat.rb)
* [diskusage](https://github.com/rubys/wunderbar/blob/master/demo/diskusage.rb)

As a bonus for following along this far, there is a 
[demo Calendar application](../demo/calendar/README.md) implemented with Wunderbar. 
