#!/usr/bin/ruby
require 'rubygems'
require 'open3'
require 'socket'

begin
  require 'em-websocket'
rescue LoadError
  module EM
    class Channel
      def initialize
        require 'em-websocket'
      end
    end
  end
end

module Wunderbar
  class Channel < EM::Channel
    attr_reader :port, :connected, :complete

    def initialize(port, limit)
      # verify that the port is available
      TCPServer.new('0.0.0.0', port).close 

      super()
      @port = port
      @connected = @complete = false
      @memory = []
      @memory_channel = subscribe do |msg| 
        @memory << msg.chomp unless Symbol === msg
        @memory.shift while @connected and limit and @memory.length > limit
      end
      websocket.run
    end

    def websocket
      return @websocket if @websocket
      ready = false
      @websocket = Thread.new do
        EM.epoll
        EM.run do
          connection = EventMachine::WebSocket::Connection
          EM.start_server('0.0.0.0', @port, connection, {}) do |ws|
            ws.onopen do
              @memory.each {|msg| ws.send msg }
              @connected = true
              ws.close_websocket if complete
            end
        
            sid = subscribe do |msg| 
              if msg == :shutdown
                ws.close_websocket
              else
                ws.send msg
              end
            end
        
            ws.onclose {unsubscribe sid}
          end
          EM.add_timer(0.1) {ready = true}
        end
      end
      sleep 0.2 until ready
      @websocket
    end

    def _(msg=nil, &block)
      return self if msg==nil 
      push(msg.to_json)
    end

    def system(command)
      Open3.popen3(command) do |pin, pout, perr|
        _ :type=>:stdin, :line=>command
        [
          Thread.new do
            pout.sync=true
            _ :type=>:stdout, :line=>pout.readline.chomp until pout.eof?
          end,
          Thread.new do
            perr.sync=true
            _ :type=>:stderr, :line=>perr.readline.chomp until perr.eof?
          end,
          Thread.new { pin.close }
        ].each {|thread| thread.join}
      end
    end

    def complete=(value)
      push :shutdown if value
      @complete = value
    end

    def close
      unsubscribe @memory_channel if @memory_channel
      EM::WebSocket.stop
      websocket.join    
    end
  end

  if defined? EventMachine::WebSocket
    def self.websocket(opts={}, &block)
      port = opts[:port]
      buffer = opts.fetch(:buffer,1)

      if not port
        socket = TCPServer.new(0)
        port = Socket.unpack_sockaddr_in(socket.getsockname).first
        socket.close
      end

      sock1, sock2 = UNIXSocket.pair

      submit do
        begin
          channel = Wunderbar::Channel.new(port, buffer)
          sock1.send('x',0)
          sock1.close
          channel.instance_eval &block
        rescue Exception => exception
          channel._ :type=>:stderr, :line=>exception.inspect
          exception.backtrace.each do |frame| 
            next if Wunderbar::CALLERS_TO_IGNORE.any? {|re| frame =~ re}
            channel._ :type=>:stderr, :line=>"  #{frame}"
          end
        ensure
          if channel
            channel.complete = true
            sleep 5
            sleep 60 unless channel.connected
            channel.close
          end
        end
      end

      sleep 0.3 while sock2.recv(1) != 'x'
      sock2.close

      port
    end
  end
end
