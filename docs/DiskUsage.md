Disk Usage
===

The Unix `du` command is a potentially long running process that produces
tabular output that practically begs for operations like _drilling down_ and
_sorting_.  As such, it is an excellent opportunity to demonstrate that the
Wunderbar helps in situations where command line scripts are otherwise called
for.

Which brings us to the next demo:
[diskusage](https://github.com/rubys/wunderbar/blob/master/demo/diskusage.rb).

Once again, we will use web sockets, but as running commands and parsing the
output line by line is such a common pattern, Wunderbar's web socket support
redefines the `system` method to send out events for every line output.  This
reduces the core of this script to the following code:

```ruby
# extract sizes in a background process
port = _.websocket {Dir.chdir(dir) {system 'du -sb *'}}
@websocket = "ws://#{env['SERVER_NAME'] || 'localhost'}:#{port}/"
```

To make this work, the HTML contains a table that serves as a blank canvas,
and is set up for sorting:

```ruby
# initial table (names and dates without sizes)
_table_ do
  _thead_ do
    _tr do
      _th 'Name', data_sort: 'string'
      _th 'Size', data_sort: 'int'
      _th 'Date', data_sort: 'date'
    end
  end

  _tbody do
    # ...
  end
end
```
Each time a message is received from `stdout`, it is parsed and compared
against every row in the table.  When a matching name is found, the size
column for that row is filled in with the number (with commas inserted to
improve readability), and with the original number added as an attribute for
sorting purposes.

```ruby
ws.onmessage = proc do |evt|
  data = JSON.parse(evt.data)
  match = data.line.match(/^(\d+)\s+(.*)/)

  # update table using output from 'du' command
  if data.type == 'stdout' and match
    ~'tbody tr'.each do
      if match and ~["td:first a", self].text == match[2]
        ~["td", self].eq(1).attr('data-sort-value', match[1]).text =
          match[1].gsub(/(\d)(?=(\d{3})+(\.|$))/, '$1,')
        match = nil
      end
    end
  end

  # ...
end
```

All other messages are added to an initially hidden area on the page, which is
scrolled to the bottom as messages come in and shown once any unexpected data
is received:

```ruby
# display all other messages received
if data.type != 'stdout' or match
  ~"#msg".append(~"<p>".text(data.line).addClass(data.type))
  ~"#msg".scrollTop = ~"#msg".prop("scrollHeight") - ~"#msg".height
  ~"#msg".show if data.type != 'stdin'
end
```

The directory itself is extracted from CGI/rack environment variables:

```ruby
# directory is DOCUMENT_ROOT + PATH_INFO
$ROOT ||= ARGV.map {|arg| arg[/^--root=(.*)/i, 1]}.compact.first.untaint
dir = ($ROOT || env['DOCUMENT_ROOT'] || Dir.pwd).dup.untaint
prefix = "#{env['REQUEST_URI']}/" if not env['PATH_INFO'].to_s.end_with?  '/'
if env['PATH_INFO'].to_s =~ %r{(/\w[-.\w]*)+/?}
  dir = File.expand_path(env['PATH_INFO'][1..-1].untaint, dir).untaint
end
```

What's notable here is that data from environment variables comes from the
outside world, and therefore is considered
[tainted](http://ruby-doc.com/docs/ProgrammingRuby/html/taint.html) and, as
Wunderbar runs scripts with `$SAFE=1`, cannot be used to access the filesystem
until [untainted](http://ruby-doc.org/core-1.9.3/Object.html#method-i-untaint).

As an alternative, the directory to be used may be specified using `$ROOT`,
which can be provided via the command line or by wrappers that call this
script.  In fact, at the end of this script are lines (minus the `__END__` of
course) that will be added to CGI wrappers that are installed:

```
__END__
# Customize what directory is searched
$ROOT = ENV['DOCUMENT_ROOT']
```

These lines can be tailored by editing the wrapper or by specifying alternate
values during the installation of the wrapper itself, for example:

```
ruby demo/diskusage.rb --install=/var/www --root=/home/rubys
```

Next up, an [Angular.js demo](AngularJS.md).
