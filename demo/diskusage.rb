require 'wunderbar'

_html do
  _head_ do
    _script src: '/jquery.min.js'
    _script src: '/jquery.tablesorter.min.js'
    _style %{
      p {margin: 0; height: 1.2em}
      table {border-spacing: 1em 0}
      th, td {padding: 0.2em 0.5em}
      th {border-bottom: solid black}
      tbody tr:hover {background-color: #FF8}
      td:nth-child(2) {text-align: right}
      #msg {display: none; height: 9em; overflow: auto; border: 1px solid}
      .stdin {color: purple}
      .stderr {color: red}
    }
  end

  _body? do
    _div.status!
    _div.msg!

    # directory is DOCUMENT_ROOT + PATH_INFO
    dir = env['DOCUMENT_ROOT'].dup.untaint
    prefix = "#{env['REQUEST_URI']}/" if not env['PATH_INFO'].to_s.end_with? '/'
    if env['PATH_INFO'].to_s.start_with? '/'
      info = File.expand_path(env['PATH_INFO'][1..-1].untaint, dir)
      info.taint unless info.start_with?(dir) and File.exist?(info)
      dir = info
    end

    _h1 dir
    
    # initial table (names and dates without sizes)
    _table_ do
      _thead do
        _tr do
          _th 'Name'
          _th 'Size'
          _th 'Date'
        end
      end
      _tbody do
        Dir.chdir(dir) do
          Dir['*'].sort.each do |name|
            _tr_ do
              href = nil
              href = "#{prefix}#{name}/" if File.directory? name.untaint
              _td {_a name, href: href}
              _td
              _td File.stat(File.join(dir, name.untaint)).mtime
            end
          end
        end
      end
    end

    # extract sizes in a background process
    port = _.websocket {Dir.chdir(dir) {system 'du -sb *'}}

    _script %{
      ws = new WebSocket("ws://#{env['HTTP_HOST']}:#{port}/");
      ws.onclose = function() {$("#status").html("<p>socket closed.</p>")}
      ws.onopen  = function() {$("#status").html("<p>socket connected...</p>")};

      ws.onmessage = function(evt) {
        var data = JSON.parse(evt.data);
        var match = data.line.match(/^(\\d+)\\s+(.*)/);

        // update table using output from 'du' command
        if (data.type == 'stdout' && match) {
          $('tbody tr').each(function() {
            if (match && $("td:first a", this).text() == match[2]) {
              $("td", this).eq(1).text(match[1])
              match = null
            }
          })
        }

        // display all other messages received
        if (data.type != 'stdout' || match) {
          var msg = $("#msg");
          msg.append($("<p></p>").text(data.line).addClass(data.type)); 
          msg.prop('scrollTop', msg.prop("scrollHeight") - msg.height());
          if (data.type != 'stdin') msg.show();
        }

        // make table sortable
        $('table').tablesorter();
      }
    }
  end
end

__END__
# Customize what directory is searched
$ROOT = ENV['DOCUMENT_ROOT']
