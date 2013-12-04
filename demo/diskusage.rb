require 'wunderbar/websocket'
require 'wunderbar/jquery/stupidtable'
require 'ruby2js/filter/functions'

_html do
  _head_ do
    _style %{
      p {margin: 0.2em 0.5em}
      table {border-spacing: 1em 0}
      th, td {padding: 0.2em 0.5em}
      th {border-bottom: solid black}
      tbody tr:hover {background-color: #FF8}
      td:nth-child(2) {text-align: right}
      #msg {display: none; height: 9em; overflow: auto; border: 4px solid red;
        background-color: #FFE; border-radius: 1em}
      legend {margin-left: 5%; border: 3px solid red; border-radius: 0.5em}
      .stdin {color: purple}
      .stderr {color: red}
      .sorting-desc:after {content: "\u2193"}
      .sorting-asc:after {content: "\u2191"}
    }
  end

  _body? do
    _div.status!
    _fieldset.msg! {_legend 'error log'}

    # directory is DOCUMENT_ROOT + PATH_INFO
    $ROOT ||= ARGV.map {|arg| arg[/^--root=(.*)/i, 1]}.compact.first.untaint
    dir = ($ROOT || env['DOCUMENT_ROOT'] || Dir.pwd).dup.untaint
    prefix = "#{env['REQUEST_URI']}/" if not env['PATH_INFO'].to_s.end_with? '/'
    if env['PATH_INFO'].to_s =~ %r{(/\w[-.\w]*)+/?}
      dir = File.expand_path(env['PATH_INFO'][1..-1].untaint, dir).untaint
    end

    _h1 "Disk Usage: #{dir}"

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
        Dir.chdir(dir) do
          Dir['*'].sort.each do |name|
            _tr_ do
              href = nil
              href = "#{prefix}#{name}/" if File.directory? name.untaint
              _td {_a name, href: href}
              _td
              begin
                _td File.stat(File.join(dir, name.untaint)).mtime
              rescue Errno::ENOENT
                _td '*** missing ***'
              end
            end
          end
        end
      end
    end

    # extract sizes in a background process
    port = _.websocket {Dir.chdir(dir) {system 'du -sb *'}}
    @websocket = "ws://#{env['SERVER_NAME'] || 'localhost'}:#{port}/"

    _script do
      ws = WebSocket.new(@websocket)
      ws.onclose = proc {~"#status".hide}
      ws.onopen  = proc {~"#status".text = "collecting data..."}

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

        # display all other messages received
        if data.type != 'stdout' or match
          ~"#msg".append(~"<p>".text(data.line).addClass(data.type))
          ~"#msg".scrollTop = ~"#msg".prop("scrollHeight") - ~"#msg".height
          ~"#msg".show if data.type != 'stdin'
        end
      end

      # make table sortable
      ~'table'.stupidtable
    end
  end
end

__END__
# Customize what directory is searched
$ROOT = ENV['DOCUMENT_ROOT']
