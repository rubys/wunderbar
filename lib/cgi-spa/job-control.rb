# run command/block as a background daemon
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

    # setup environment
    ENV['USER'] ||= $USER
    ENV['HOME'] ||= $HOME

    # run cmd and/or block
    system cmd if cmd
    yield if block_given?
  end
end
