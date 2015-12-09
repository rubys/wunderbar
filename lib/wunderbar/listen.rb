#
# Runs a rack server and restarts on library changes
# (Only works on Linux and Mac OS/X)
#
# prereqs: listen, puma
#

require 'listen'

$HOME = ENV['HOME']

pids = `lsof -t -i tcp:9292`.split
system "kill -9 #{pids.join(' ')}" unless pids.empty?

start = Time.now
dirs = [Dir.pwd] + ENV['RUBYLIB'].to_s.split(':')
files = File.read('config.ru').
  scan(%r{^require\s+File.expand_path\(['"]../(.*)['"],\s+__FILE__\)$}).flatten
files.each do |file|
  file = File.read(file)
  dirs += file.scan(%r{\$:\.unshift\s+['"](.*?)['"]}).flatten
  dirs += file.scan(%r{^require ['"](/.*?)['"]}).flatten
end

dirs.uniq!
dirs.select! {|dir| Dir.exists?(dir)}

dirs.each {|dir| puts "Watching #{dir}"}
puts unless dirs.empty?

listener = Listen.to(*dirs) do |modified, added, removed|
  puts
  modified.each {|file| puts "#{file} modified"}
  added.each {|file| puts "#{file} added"}
  removed.each {|file| puts "#{file} removed"}

  elapsed, start = Time.now - start, Time.now
  if `fuser -n tcp 9292 2>/dev/null`.empty?
    Process.kill("SIGINT", $pid)
    $pid = spawn('puma', '--quiet')
  else
    Process.kill("SIGUSR2", $pid) if elapsed > 0.5
  end
end

$pid = spawn('puma', '--quiet')

listener.start
listener.ignore /\~$/
listener.ignore /^\..*\.sw\w$/

begin
  sleep
rescue Interrupt
  listener.stop
  Process.kill("SIGINT", $pid)
end
