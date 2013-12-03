Introduction, Part 1
===

It is accepted wisdom within the [Ruby on Rails](http://rubyonrails.org/)
community that the best frameworks are ones that are extracted from existing
applications.  It worked for
[Rails](http://en.wikipedia.org/wiki/Ruby_on_Rails#History).  It is also how
Wunderbar was developed.

Since I'm virtually inviting a comparison to Rails here, it makes sense to
differentiate the target audiences for both frameworks.  After all, I'm not
only a big fan of Rails, I'm an author of a successful
[Book](http://pragprog.com/book/rails4/agile-web-development-with-rails-4) on
the subject.

The competition for Wunderbar isn't Rails; it is command line applications.
Applications that make use of `STDIN`, `STDOUT`, `STDERR`, and `ARGV`.

Whereas it isn't uncommon for a Rails application to have dozens of
controllers, each with dozens of views, and serving thousands of simultaneous
users; a Wunderbar application typically has a few pages, and often only one.

It also isn't uncommon for a Wunderbar application to have only dozens of
users, and often only one.  In fact, most of the applications I have built
using this framework are deployed using CGI.

So with all this said, why a new framework?  The answer is simple: while I am
also a fan of the command line, there are many times where a HTML form is
easier to use than `ARGV`, and scrolling through a web page is easier than
scrolling through a Terminal window.  Particularly if the data is formatted
or tabular.

Before continuing with the introduction, it makes sense to explore a few
demo applications.

Let's start with [hello world](HelloWorld1.md)
