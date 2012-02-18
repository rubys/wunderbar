#!/usr/bin/ruby
require 'wunderbar'
require 'rdiscount'
require 'shellwords'

Dir.chdir WIKIDATA

# parse request
%r{/(?<file>.\w+)((?<flag>/)(?<rev>\w*))?$} =~ $env.PATH_INFO
flag ||= '?' if $env.REQUEST_URI.include? '?'
file ||= 'index'

Wunderbar.html do
  _head do
    _.warn 'hi'
    _title file
    _style %{
      body {background-color: #{(flag=='?') ? '#E0D8D8' : '#FFF'}}
      .status {border: 2px solid #000; border-radius: 1em; background: #FAFAD2; padding: 0.5em}
      .input, .output {border: 1px solid #888; position: relative; width: 47.5%; height: 400px; overflow: auto}
      .input {float: left; left: 1.5%}
      .output {float: right; right: 1.5%; background-color: #6C6666; color: #FFF}
      .buttons {clear: both; text-align: center; padding-top: 0.5em}
      .message {position: fixed; left: 2%; color: #9400d3}
      h1 {text-align: center; margin: 0}
      form {clear: both}
      .buttons form {display: inline}
      ._stdin:before {content: '$ '}
      ._stdin {color: #9400D3; margin-bottom: 0}
      ._stdout {margin: 0}
      ._stderr {margin: 0; color: red}
    }
    _script src: '/showdown.js'
    _script src: '/jquery.min.js'
  end

  _body? do

    # determine markup
    if _.post? and @markup
      File.open(file, 'w') {|fh| fh.write @markup}
      _header class: 'status' do
        _h1 'Status'
        _.system 'git init' unless Dir.exist? '.git'
        if `git status --porcelain #{file}`.empty?
          _p 'Nothing changed'
        else
          _.system "git add #{file}"
          _.system "git commit -m #{@comment.shellescape} #{file}"
        end
      end
    elsif File.exist? file
      if !rev or rev.empty?
        @markup = File.read(file) 
      else
        @markup = `git show #{rev}:#{file}`
        flag = nil
      end
    else
      # new file: go directly into edit mode
      @markup = "#{file}\n#{'-'*file.length}\n\nEnter your text here..."
      flag = '?'
    end

    # produce HTML
    if flag == '?'

      # edit mode
      _header do
        _h1 "~~~ #{file} ~~~"
        _span 'Input', style: 'float: left; margin-left: 2em'
        _span 'Output', style: 'float: right; margin-right: 2em'
      end

      _form action: file, method: 'post' do
        _textarea @markup, name: 'markup', class: 'input'
        _div class: 'output' do
          _ << RDiscount.new(@markup).to_html
        end

        _div class: 'buttons' do
          _span class: 'message'
          _input name: 'comment', placeholder: 'commit message'
          _input type: 'submit', value: 'save'
        end
      end

    elsif flag == '/'

      # revision history
      _h2 "Revision history for #{file}"
      _ul do
        `git log --format="%H|%ai|%an|%s" #{file}`.lines.each do |line|
          hash, date, author, subject = line.split('|')
          _li! {_a date, href: hash; _ " #{subject} by #{author}"}
        end
      end

    else

      #display
      _ << RDiscount.new(@markup).to_html
      _div class: 'buttons' do
        if !rev or rev.empty?
          _form action: "#{file}?", method: 'post' do
            _input type: 'submit', value: 'edit'
          end
        end
        _form action: "#{file}/" do
          _input type: 'submit', value: 'history'
        end
      end
    end

    _script %{
      // autosave every 10 seconds
      var dirty = false;
      setInterval(function() {
        if (!dirty) return;
        dirty = false;
        var markup = $('textarea[name=markup]').val();
        $.getJSON("#{SELF}", {markup: markup}, function(response) {
          var time = new Date(response.time).toLocaleTimeString();
          $('.message').text("Autosaved at " + time).show().fadeOut(5000);
        });
      }, 10000);

      // update output pane and mark dirty whenever input changes
      var converter = new Showdown.converter();
      $('.input').bind('input', function() {
        dirty = true;
        $('.output').html(converter.makeHtml($(this).val()));
      }).trigger('input');

      // resize based on window size
      var reserve = $('header').height() * 3 + $('.buttons').height();
      $(window).resize(function() {
        $('.input,.output').height($(window).height()-reserve);
      }).trigger('resize');
    }
  end
end

# process autosave requests
Wunderbar.json do
  File.open(file, 'w') {|fh| fh.write @markup}
  {time: Time.now.to_i*1000}
end

__END__
# Customize where the wiki data is stored
WIKIDATA = '/full/path/to/data/directory'
