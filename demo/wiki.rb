#!/usr/bin/ruby
require 'wunderbar'
require 'rdiscount'
require 'digest/md5'

Dir.chdir WIKIDATA

# parse request
%r{/(?<file>.\w+)((?<flag>/)(?<rev>\w*))?$} =~ $env.PATH_INFO
flag ||= '?' if $env.REQUEST_URI.include? '?'
file ||= 'index'

W_.html do
  _head_ do
    _title file
    _style %{
      body {background-color: #{(flag=='?') ? '#E0D8D8' : '#FFF'}}
      .status {border: 2px solid #000; border-radius: 1em; background: #FAFAD2; padding: 0.5em}
      .input, .output {border: 1px solid #888; position: relative; width: 47.5%; height: 400px; overflow: auto}
      .input {float: left; left: 1.5%}
      .output {float: right; right: 1.5%; background-color: #6C6666; color: #FFF}
      .buttons {clear: both; text-align: center; padding-top: 0.5em}
      #message {position: fixed; left: 2%; color: #9400d3}
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
      _header.status do
        _h1 'Status'
        if File.exist?(file) and Digest::MD5.hexdigest(File.read(file)) != @hash
          _p 'Write conflict'
        else
          File.open(file, 'w') {|fh| fh.write @markup}
          _.system 'git init' unless Dir.exist? '.git'
          if `git status --porcelain #{file}`.empty?
            _p 'Nothing changed'
          else
            _.system "git add #{file}"

            commit = %w(git commit) 
            commit << '--author' << $EMAIL if defined? $EMAIL and $EMAIL
            commit << '--message' << @comment
            commit << file 

            _.system commit
          end
        end
      end

    elsif File.exist? file
      # existing file
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
    if file == '_index'

      # index
      index = Hash[`git ls-tree HEAD --name-only`.scan(/(\w+)()/)].
        merge Hash[*`git status --porcelain`.scan(/(..) (\w+)/).flatten.reverse]
      _table do
        _tbody do
          index.sort.each do |name, status|
            _tr do
              _td status
              _td {_a name, href: name}
            end
          end
        end
      end

    elsif flag == '?'

      # edit mode
      _header do
        _h1 "~~~ #{file} ~~~"
        _span 'Input', style: 'float: left; margin-left: 2em'
        _span 'Output', style: 'float: right; margin-right: 2em'
      end

      _form_ action: file, method: 'post' do
        _textarea.input @markup, name: 'markup'
        _input type: 'hidden', name: 'hash', 
          value: Digest::MD5.hexdigest(@markup)
        _div.output do
          _ << RDiscount.new(@markup).to_html
        end

        _div.buttons do
          _span.message!
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
      _div_.buttons do
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

        var params = {
          markup: $('textarea[name=markup]').val(),
          hash:   $('input[name=hash]').val()
        };

        $.getJSON("#{_.SELF}", params, function(_) {
          $('input[name=hash]').val(_.hash);
          if (_.time) {
            var time = new Date(_.time).toLocaleTimeString();
            $('#message').text("Autosaved at " + time).show().fadeOut(5000);
          } else {
            $('.input').val(_.markup).attr('readonly', 'readonly');
            $('#message').css({'font-weight': 'bold'}).text(_.error).show();
          }
        });
      }, 10000);

      // regenerate output every 0.5 seconds
      var updated = false;
      setInterval(function() {
        if (!updated) return;
        updated = false;
        $('.output').html(converter.makeHtml($('.input').val()));
      }, 500);

      // update output pane and mark dirty whenever input changes
      var converter = new Showdown.converter();
      $('.input').bind('input', function() {
        updated = dirty = true;
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
W_.json do
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

__END__
# Customize where the wiki data is stored
WIKIDATA = '/full/path/to/data/directory'

# git author e-mail address override
require 'wunderbar'
require 'etc'
begin
  name = Etc.getpwnam($USER).gecos.split(',').first
  $EMAIL = "#{name} <#{$USER}@#{$env.SERVER_NAME}>"
  $EMAIL = nil if %w(www-data _www).include?($USER)
rescue
end
