# Instructions: set this up to run as CGI.  In a separate window, run this
# same script from the command line.  Point multiple browsers at the CGI
# window, and change the textarea from in each.

require 'wunderbar'

port = 8080

if ENV['SERVER_PORT']

  _html do
    _head do
      _title 'Chat server'
      _script src: '/jquery.min.js'
      _style %{
        textarea {width: 100%; height: 10em}
        #error {color: red; margin-top: 1em}
        #error pre {margin: 0}
      }
    end
    _body do
      _h1 "Chat on port # #{port}"
      _textarea
      _div.status!
      _div.error!

      _script %{
        ws = new WebSocket("ws://#{env['HTTP_HOST']}:#{port}/");
        $('textarea').bind('input', function() { ws.send($(this).val()); });

        ws.onmessage = function(evt) { 
          data = JSON.parse(evt.data);
          if (data.type == 'status') {
            $('#status').text(data.line);
          } else if (data.type == 'stderr') {
            $("#error").append($('<pre></pre>').text(data.line));
          } else {
            $('textarea').val(data.line);
          }
        };

        ws.onclose = function(evt) {
          $('textarea').attr('readonly', true);
          $('#status').text('chat terminated')
        };
      }
    end
  end

else

  # echo server
  puts "Waiting on port #{port}"
  _websocket(port: port) do
    count = 0
    timer = 10

    _.onopen do
      count += 1
      _ type: 'status', line: "waiting for others to join" if count == 1
      _ type: 'status', line: "#{count} members in chat" if count > 1
    end

    _.subscribe do |msg| 
      puts msg
      _ type: 'msg', line: msg
    end

    _.onclose do
      count -= 1
      _ type: 'status', line: "waiting for others to join" if count == 1
      _ type: 'status', line: "#{count} members in chat" if count > 1
    end

    loop do
      begin
        sleep 60
        timer -= 1
        timer = 10 if count > 0
        break if timer <= 0
      rescue Interrupt
        puts 'Shutting down'
        _ type: 'status', line: 'shutting down'
        break
      end
    end
  end

end
