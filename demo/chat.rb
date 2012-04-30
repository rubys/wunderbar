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
      }
    end
    _body do
      _h1 "Chat on port # #{port}"
      _textarea
      _script %{
        ws = new WebSocket("ws://#{env['HTTP_HOST']}:#{port}/");
        ws.onmessage = function(evt) { $('textarea').val(evt.data); }
        $('textarea').bind('input', function() { ws.send($(this).val()); });
      }
    end
  end

else

  # echo server
  puts "Waiting on port #{port}"
  _websocket(port: port) do
    _.subscribe do |msg| 
      puts msg
      _.push msg
    end
    sleep 900
  end

end
