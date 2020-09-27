require 'wunderbar/script'
require 'wunderbar/jquery'
require 'wunderbar/markdown'
require 'wunderbar/pagedown'
require 'ruby2js/filter/functions'
require 'digest/md5'
require 'escape'

Dir.chdir WIKIDATA

# parse request
%r{/(?<file>\w[-\w]+)((?<flag>/)(?<rev>\w*))?$} =~ env['PATH_INFO']
flag ||= '?' if env['REQUEST_URI'].to_s.include? '?'
file ||= 'index'

_html _width: $WIDTH do
  _head_ do
    _title file
    _style %{
      body {background-color: #{(flag=='?') ? '#E0D8D8' : '#FFF'}}

      .status {border: 2px solid #000; border-radius: 1em; background: #FAFAD2; padding: 0.5em}
      ._stdin:before {content: '$ '}
      ._stdin {color: #9400D3; margin-bottom: 0}
      ._stdout {margin: 0}
      ._stderr {margin: 0; color: red}

      h1 {text-align: center; margin: 0}

      .input, .output {border: 1px solid #888; position: relative; width: 47.5%; height: 400px; overflow: auto}
      .input {float: left; left: 1.5%}
      .output {float: right; right: 1.5%; background-color: #6C6666; color: #FFF}

      .buttons {clear: both; text-align: center; padding-top: 0.5em}
      #message {position: absolute; left: 2%; color: #9400d3}
      .buttons:hover #message {opacity: 0.7; color: black; display:inline !important}
      form {clear: both}
      .buttons form {display: inline}
    }
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
              _td! {_a name, href: name}
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
          _markdown @markup
        end

        _div.buttons do
          _span.message!
          _input.comment! name: 'comment', placeholder: 'commit message'
          _input.save! type: 'submit', value: 'save'
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
      _div_.content do
        _markdown @markup
      end

      _div_.buttons do
        _span.message!
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

    @uri = env['REQUEST_URI']

    _script do
      # autosave every 5 seconds
      dirty = false
      setInterval 5000 do
        return unless dirty
        dirty = false

        params = {
          markup: ~'textarea[name=markup]'.val,
          hash:   ~'input[name=hash]'.val
        }

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
      end

      # regenerate output every second
      updated = false
      setInterval 1000 do
        return unless updated
        updated = false
        ~'.output'.html = converter.makeHtml(~'.input'.val)
      end

      # update output pane and mark dirty whenever input changes
      converter = Markdown::Converter.new()
      ~'.input'.on(:input) do
        updated = dirty = true
        ~'#save'.disabled = true
      end

      # watch for updates
      watch = ~'<input type="submit" value="watch"/>'
      watch.click do
        watcher = proc do
          $$.ajax(url: @uri, ifModified: true,
            dataType: 'text', accepts: {text: 'text/plain'},
            success: proc do |markup|
              ~'.content'.html = converter.makeHtml(markup)
              time = Date.new().toLocaleTimeString()
              ~'#message'.text("Updated at #{time}").show.fadeOut(5000)
            end
          )
        end
        watcher()
        setInterval(watcher, 10000)
        ~this.hide
        return false
      end
      ~'.buttons form'.first.prepend(watch)

      # disable save button until there is a commit message
      ~'#save'.disabled = true
      ~'#comment'.on(:input) do
        ~'#save'.disabled = false unless dirty
      end

      # resize based on window size
      reserve = ~'header'.height * 2.5 + ~'.buttons'.height
      ~window.resize {
        ~'.input,.output'.height(~window.height - reserve)
      }.trigger(:resize)
    end
  end
end

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

# allow the raw markdown to be fetched
_text do
  _ File.read(file) if File.exist?(file)
end

__END__
# Customize where the wiki data is stored
WIKIDATA = '/full/path/to/data/directory'

# Width to wrap lines in output HTML produced (remove to disable wrapping)
$WIDTH = 80

# git author e-mail address override
require 'wunderbar'
require 'etc'
begin
  name = Etc.getpwnam($USER).gecos.split(',').first
  $EMAIL = "#{name} <#{$USER}@#{ENV['SERVER_NAME']}>"
  $EMAIL = nil if %w(www-data _www).include?($USER)
rescue
end
