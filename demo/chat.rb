# Instructions: install em-websocket parser gems.  Then set this script up to
# run as CGI.  In a separate window, run this same script from the command
# line.  Point multiple browsers at the CGI window, and change the textarea
# from in each.

require 'wunderbar/jquery'
require 'wunderbar/websocket'

PORT = 8080

if ENV['SERVER_PORT']

  _html do
    _style_ %{
      textarea {width: 100%; height: 10em}
      #error {color: red; margin-top: 1em}
      #error pre {margin: 0}
    }

    _h1_ "Chat on port # #{PORT}"
    _textarea
    _div.status!
    _div.error!

    @socket = "ws://#{env['HTTP_HOST']}:#{PORT}/"

    _script_ do
      ws = WebSocket.new(@socket)
      ~'textarea'.on(:input) { ws.send(~this.val) }

      ws.onmessage = proc do |evt|
        data = JSON.parse(evt.data)

        case data.type
        when 'status'
          ~'#status'.text = data.line
        when 'stderr'
          ~"#error".append(~'<pre>').text = data.line
        else
          ~'textarea'.val = data.line
        end
      end

      ws.onclose = proc do
        ~'textarea'.readonly = true
        ~'#status'.text = 'chat terminated'
      end
    end
  end

else

  # echo server
  puts "Waiting on port #{PORT}"
  _websocket(port: PORT) do
    count = 0
    timer = 10
    content = ''

    _.onopen do
      count += 1
      _ type: 'status', line: "waiting for others to join" if count == 1
      _ type: 'status', line: "#{count} members in chat" if count > 1
      _ type: 'msg', line: content
    end

    _.subscribe do |msg| 
      puts msg
      _ type: 'msg', line: msg
      content = msg
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
