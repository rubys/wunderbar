#!/usr/bin/ruby
require 'cgi'
require 'rubygems'
require 'builder'
require 'json'

# standard objects
$cgi = CGI.new
$param = $cgi.params
$x = Builder::XmlMarkup.new :indent => 2

# fast path for accessing CGI parameters
def $param.method_missing(name)
  self[name.to_s].join 
end

# environment objects
$USER = ENV['USER'] ||
  if RUBY_PLATFORM =~ /darwin/
    `dscl . -search /Users UniqueID #{Process.uid}`.split.first
  else
    `getent passwd #{Process.uid}`.split(':').first
  end

$HOME   = ENV['HOME'] || File.expand_path('~' + $USER)
$SERVER = ENV['HTTP_HOST'] || `hostname`.chomp

# request types
$HTTP_GET  = ($cgi.request_method == 'GET')
$HTTP_POST = ($cgi.request_method == 'POST')
$XHR_JSON  = (ENV['HTTP_ACCEPT'] =~ /json/)

# run command/block as a background daemon
def submit(cmd=nil)
  fork do
    # detach from tty
    Process.setsid
    fork and exit

    # clear working directory and mask
    Dir.chdir '/'
    File.umask 0000

    # close open files
    STDIN.reopen '/dev/null'
    STDOUT.reopen '/dev/null', 'a'
    STDERR.reopen STDOUT

    # setup environment
    ENV['USER'] ||= $USER
    ENV['HOME'] ||= $HOME

    # run cmd and/or block
    system cmd if cmd
    yield if block_given?
  end
end

# add indented_text!, indented_data! and traceback! methods to builder
module Builder
  class XmlMarkup
    unless method_defined? :indented_text!
      def indented_text!(text)
        indented_data!(text) {|data| text! data}
      end
    end

    unless method_defined? :indented_data!
      def indented_data!(data)
        return if data.strip.length == 0
        lines = data.gsub(/\n\s*\n/,"\n")
        unindent = lines.scan(/^ */).map {|str| str.length}.min

        before  = Regexp.new('^'.ljust(unindent+1))
        after   =  " " * (@level * @indent)
        data = data.gsub(before, after)

        if block_given?
          yield data 
        else
          self << data
        end

        _newline unless data =~ /\s$/
      end
    end

    unless method_defined? :traceback!
      def traceback!(exception=$!, klass='traceback')
        pre :class=>klass do
          text! exception.inspect
          _newline
          exception.backtrace.each {|frame| text!((' '*@indent)+frame + "\n")}
        end
      end
    end
  end
end

# monkey patch to ensure that tags are closed
test = 
  Builder::XmlMarkup.new.html do |x|
    x.body do
     begin
       x.p do
         raise Exception.new('boom')
       end
     rescue Exception => e
       x.pre e
     end
    end
  end

if test.index('<p>') and !test.index('</p>')
  module Builder
    class XmlMarkup
      def method_missing(sym, *args, &block)
          text = nil
        attrs = nil
        sym = "#{sym}:#{args.shift}" if args.first.kind_of?(Symbol)
        args.each do |arg|
          case arg
          when Hash
            attrs ||= {}
            attrs.merge!(arg)
          else
            text ||= ''
            text << arg.to_s
          end
        end
        if block
          unless text.nil?
            raise ArgumentError, "XmlMarkup cannot mix a text argument with a block"
          end
          _indent
          _start_tag(sym, attrs)
          _newline
          begin ### Added
            _nested_structures(block)
          ensure ### Added
            _indent
            _end_tag(sym)
            _newline
          end ### Added
        elsif text.nil?
          _indent
          _start_tag(sym, attrs, true)
          _newline
        else
          _indent
          _start_tag(sym, attrs)
          text! text
          _end_tag(sym)
          _newline
        end
        @target
      end
    end
  end
end
