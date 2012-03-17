# run command/block as a background daemon
module Wunderbar
  def submit(cmd=nil)
    fork do
      # detach from tty
      Process.setsid
      fork and exit

      # clear working directory and mask
      Dir.chdir '/'
      File.umask 0000

      # close open files
      STDIN.reopen '/dev/null'
      STDOUT.reopen '/dev/null', 'a'
      STDERR.reopen STDOUT

      # clear environment of cgi cruft
      ENV.keys.to_a.each do |key|
        ENV.delete(key) if key =~ /HTTP/ or $cgi.respond_to? key.downcase
      end

      # setup environment
      ENV['USER'] ||= $USER
      ENV['HOME'] ||= $HOME

      # run cmd and/or block
      system cmd if cmd
      yield if block_given?
    end
  end
end
