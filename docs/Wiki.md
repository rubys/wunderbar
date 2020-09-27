Wiki
====

The [wiki demo](https://github.com/rubys/wunderbar/blob/master/demo/wiki.html)
is considerably larger than what we have seen before, and so all we will cover
here is selected portions that highlight additional Wunderbar features.  While
this demo isn't completely polished, it is functional.  In fact, I have used
it frequently to enable ad-hoc collaboration or even simple note taking.  This
wiki does implement some features that aren't commonly present in other wiki
systems.  Features like live preview, autosave, and watch.

The core idea is that with
[Markdown](http://daringfireball.net/projects/markdown/) as a wiki syntax and
with [git](http://git-scm.com/downloads) as a versioned backing store, all
that remains is a user interface.

Running commands and presenting the output is a common feature of scripts.
Wunderbar provides a `_.system` method to help.  It will echo the command you
provide and will turn each line of output into a separate `<pre>` elements that
you can style however you like:

```ruby
_html do
  _style %{
    ._stdin:before {content: '$ '}
    ._stdin {color: #9400D3; margin-bottom: 0}
    ._stdout {margin: 0}
    ._stderr {margin: 0; color: red}
  }

  _.system "git add #{file}"
end
```

Shell escaping of arguments is a common requirement, and will
be handled automatically by Wunderbar if the argument to `_.system` is an
array:

```ruby
commit = %w(git commit)
commit << '--author' << $EMAIL if defined? $EMAIL and $EMAIL
commit << '--message' << @comment
commit << file

_.system commit
```

If the [escape](http://rubygems.org/gems/escape) Ruby gem is included, it will
be used instead of
[Shellwords](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/shellwords/rdoc/Shellwords.html)
as it tends to produce more readable output.

One feature not shown here is that arrays may be nested, and if this is done
the nested content is not echoed back.  This is useful for passwords:

```ruby
_.system ['svn', 'commit', '--username', $USER, ['--password', secret]]
```

Markdown is supported by an optional plugin:

```ruby
require 'wunderbar/markdown'

_html do
  _markdown 'text'
end
```

Use of the Markdown feature requires
[kramdown](http://rubygems.org/gems/kramdown),
[nokogiri](http://rubygems.org/gems/nokogiri), and
[sanitize](http://rubygems.org/gems/sanitize), the latter being used if the
input is tainted (which is the case in this wiki application).

This wiki will autosave changes every 5 seconds using _Ajax_ calls back to
the same page on the server:

```ruby
require 'ruby2js/filter/functions'

_html do
  @uri = env['REQUEST_URI']

  _script do
    dirty = false
    setInterval 5000 do  
      return unless dirty
      dirty = false

      params = {
        markup: ~'textarea[name=markup]'.val,
        hash:   ~'input[name=hash]'.val
      }

      $$.post(@uri, params) do |response|
        # ...
      end
    end

    ~'.input'.on(:input) do
      dirty = true
    end
  end
end
```

What this code does is set `dirty` to `true` every time input occurs.  Every
`5000` miliseconds, the `dirty` flag is checked, and when set, an Ajax `POST`
request is sent to the server with the current values of the `textarea` and
the (hidden) hash `input` field.  Along the way, the `dirty` flag is reset,
preventing additional Ajax requests until the input field changes again.

The `functions` filter provides some useful transformations of the Ruby script
that affects the JavaScript output.  In this case, we make use of the
transformation which allows `setInterval` to be passed a block.  Without this
transformation, the block would still be converted into a `function`, but
would be passed as the _final parameter on the call.  This transformation
will reorder the parameters.

The AJAX requests are to the same page, so the wiki script will be invoked
again.  Wunderbar will detect that the request is an Ajax request, and will
execute the `_json` block instead of the `_html` one:

```ruby
# process autosave requests
_json do
  hash = Digest::MD5.hexdigest(@markup)
  if File.exist?(file) and Digest::MD5.hexdigest(File.read(file)) != @hash
    _error "Write conflict"
    _markup File.read(file)
  else
    File.open(file, 'w') {|fh| fh.write @markup} unless @hash == hash
    _time Time.now.to_i*1000
  end
  _hash hash
end
```

Once again, the parameters passed in are placed into instance
variables for easy access.

Output from `_json` is, as you might expect, is expressed as JSON, and
typically as a hash (a.k.a., key/value pairs).  `_json` accumulates these keys
and values by capturing method calls that start with an underscore.  So in
this case, the response will either contain three pairs (error, markup, and
hash) or two pairs (time and hash), depending on whether a write conflict
occurred.

Note that times in Ruby are in seconds, and times in JavaScript are in
milliseconds, and therefore the Time is multiplied by 1000 before being passed
to the client.

Now lets look at the client processing of this response:

```ruby
$$.post(@uri, params) do |response|
  ~'input[name=hash]'.val = response.hash
  if response.time
    time = Date.new(response.time).toLocaleTimeString()
    ~'#message'.text("Autosaved at #{time}").show.fadeOut(5000)
  else
    ~'.input'.val(response.markup).readonly = true
    ~'#message'.css(fontWeight: 'bold').text(response.error).show
  end

  ~'#save'.disabled = false if ~'#comment'.val != ''
end
```

The `hash` is stashed into a hidden input variable.  The `time`, if present,
is converted to the current locale, and is used to replace the contents of the
HTML element with an id of message.  This area is then shown (it previously
was hidden) and fades out over 5 seconds.  If the time is not present, the
input field is replaced with the servers view of what the latest markup is and
set to readonly.  The message field is set to bold, the text is set to the
response, and finally the message field itself is shown.

This excerpt highlights the nearly seamless information flow made possible by
Wunderbar.  `@uri` was computed on the server in response to the original HTML
request, the `params` are computed on the client, sent back to the server,
which returns back `response.time`, which is placed back on the page with
the help of jQuery.

In addition to json, Wunderbar support plain text.  The wiki demo uses this to
return the original markdown source.

```
# allow the raw markdown to be fetched
_text do
  _ File.read(file) if File.exist?(file)
end
```

The script itself concludes with:

```ruby
__END__
# Customize where the wiki data is stored
WIKIDATA = '/full/path/to/data/directory'
```

This enables one to create a new wiki using a CGI wrapper via the following
command:

```
ruby demo/wiki.rb --install=/var/www/mywiki.cgi --wikidata=/var/data/mywiki
```

A final note: the end data section also includes:

```ruby
# Width to wrap lines in output HTML produced (remove to disable wrapping)
$WIDTH = 80
```

And this value is referenced in the html itself:

```
_html _width: $WIDTH do
  #...
end
```

When this is enabled, Wunderbar will make an attempt to keep each line of
output within the specified width.  Admittedly, not many people will view
source on the HTML generated by a Wiki, but those that do will be pleasantly
surprised.  Inline scripts and styles will be properly intended, and line
breaks will be added to content when doing so doesn't change what will be
displayed.

Producing meticulous and lovingly crafted output is a design goal for
Wunderbar.

Next up, a discussion of various techniques to introduce
[modularity](Modularity.md) into your Wunderbar application.
