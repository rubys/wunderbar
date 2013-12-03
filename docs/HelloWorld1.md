HelloWorld
===

It is tradition to start with a Hello World application.  So without further
ado:

```
sudo gem install wunderbar
ruby -r wunderbar -e "_html {_h1 'Hello World'}" -- --port=8000
```

Test this program by traversing to [http://localhost:8000/](http://localhost:8000/) using your favorite web browser.  

Admittedly, you are not generally going to create entire web applications and
run them using the command line.  Instead you will want to put the code into a
file.  Something like `helloworld.rb`:

```ruby
#!/usr/bin/ruby
require 'wunderbar'

_html do
  _h1 'Hello World'
end
```

If you run this, using `ruby helloworld.rb`, the HTML that is produced will come
to the screen.  If you want to start a web server instead, pass a port, thus:

    ruby helloworld.rb --port=8000

Once you have verified it works, you can stop the web server using control-C.
You can change to a web server like [puma](http://puma.io/) or
[thin](http://code.macournoyer.com/thin/), by simply installing the
corresponding gem.

(Optional) Configuring as CGI
---

As stated in the introduction, most of my applications are deployed using
basic CGI.  In my case, I use Apache web server, using two basic strategies.

In many cases, I simply place the script into the web server's document root
directory (on Ubuntu, that's `/var/www`.  On OS X that's
`/Library/WebServer/Documents`), or on the user's directory (`~/public_html`
or `~/Sites`).  Just be sure to configure CGI in
either your `httpd.conf` file or in a `.htaccess` file.

    Options +ExecCGI +MultiViews
    MultiViewsMatch Any
    AddHandler cgi-script .cgi

Note: `MultiViews` isn't required, but if configured this way it will make it
unnecessary for users visiting your page to add the trailing `.cgi` to the
path.

The final step is to rename the file to end with `.cgi` and mark the file as
executable via `chmod 755`.  With this in place, you can visit the page using
your browser.  Make a change and hit refresh and see it instantly.

The second strategy is to leave the file in place and produce a wrapper.  This
is accomplished by running the original executable with a parameter telling it
where to install the wrapper:

    ruby helloworld.rb --install=~/public_html

A typical wrapper will look something like the following:

```
#!/usr/bin/ruby1.9.1
Dir.chdir "/home/rubys/tmp"
require "./helloworld"
```

If these instructions don't make sense to you, or CGI isn't exactly your cup
of tea, then feel free to ignore them.  Later, we will see how to run your
application using Sinatra, Rails, Rack, or any server that Rack supports,
including Apache or nginx.  Generally, these options require a bit more
configuration, but result in an application that stays in memory and therefore
responds faster to requests.

Continuing with the tutorial
---

Next up, a _slightly_ more [complicated version of hello world](HelloWorld2.md).
