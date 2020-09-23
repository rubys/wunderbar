require 'wunderbar'
require 'rbconfig'

# run command/block as a background daemon
module Wunderbar
  def self.submit(cmd=nil)
    fork do
      # detach from tty
      Process.setsid
      fork and exit

      # clear working directory and mask
      Dir.chdir '/'
      File.umask 0000

      # close open files
      STDIN.reopen '/dev/null'
      if RbConfig::CONFIG['host_os'] =~ /darwin|mac os/
        STDOUT.reopen '/dev/null'
      else
        STDOUT.reopen '/dev/null', 'a'
      end
      STDERR.reopen STDOUT

      # clear environment of cgi cruft
      require 'cgi'
      ENV.keys.select {|key| key =~ /^HTTP_/}.each do |key|
        ENV.delete key
      end
      ::CGI::QueryExtension.public_instance_methods.each do |method|
        ENV.delete method.to_s.upcase
      end

      # run cmd and/or block
      system({'USER' => $USER, 'HOME' => $HOME}, cmd) if cmd
      yield if block_given?
    end
  end
end
