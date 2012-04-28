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
    attr_reader :port

    def initialize(port, limit=nil)
      TCPSocket.new('localhost', port).close
      raise ArgumentError.new "Socket #{port} is not available"
    rescue Errno::ECONNREFUSED
      super()
      @port = port
      @memory = []
      @memory_channel = subscribe do |msg| 
        @memory << msg.chomp unless Symbol === msg
        @memory.shift while limit and @memory.length > limit
      end
      websocket.run
    end

    def websocket
      @websocket ||= Thread.new do
        EM::WebSocket.start(:host => '0.0.0.0', :port => @port) do |ws|
          ws.onopen {@memory.each {|msg| ws.send msg }}
      
          sid = subscribe do |msg| 
            if msg == :shutdown
              ws.close_websocket
            else
              ws.send msg
            end
          end
      
          ws.onclose {unsubscribe sid}
        end
      end
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

    def close
      unsubscribe @memory_channel if @memory_channel
      push :shutdown
      sleep 1
      EM::WebSocket.stop
      websocket.join    
    end
  end

  if defined? EventMachine::WebSocket
    def self.websocket(port=nil, &block)
      if not port
        socket = TCPServer.new(0)
        port = Socket.unpack_sockaddr_in(socket.getsockname).first
        socket.close
      end

      submit do
        begin
          channel = Wunderbar::Channel.new(port)
          channel.instance_eval &block
        rescue Exception => exception
          channel._ :type=>:stderr, :line=>exception.inspect
          exception.backtrace.each do |frame| 
            next if Wunderbar::CALLERS_TO_IGNORE.any? {|re| frame =~ re}
            channel._ :type=>:stderr, :line=>"  #{frame}"
          end
        ensure
          channel.push :shutdown
          sleep 5
          channel.close if channel
        end
      end

      sleep 1

      port
    end
  end
end
