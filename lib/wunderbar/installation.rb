# option to create an suexec callable wrapper
install = ARGV.find {|arg| arg =~ /--install=(.*)/}
if install and ARGV.delete(install)

  # scope out the situation
  dest = File.expand_path($1)
  main = File.expand_path(caller.last[/^(.*):\d+(:|$)/,1])

  # if destination is a directory, determine an appropriate file name
  if File.directory?(dest)
    if dest =~ /\/cgi-bin\/?$/
      dest = File.join(dest, File.basename(main))
    else
      dest = File.join(dest, File.basename(main).sub(/\.rb$/,'.cgi'))
    end
  end

  # prevent accidental overwrite
  if File.exist?(dest) and not ARGV.delete('-f')
    STDERR.puts "File #{dest} already exists.  (Specify -f to overwrite)"
    Process.exit
  end

  # ensure destination directory exists
  destdir = File.dirname(dest)
  if not File.exist?(destdir) or not File.directory?(destdir)
    STDERR.puts "Directory #{destdir} does not exist."
    Process.exit
  end

  # output wrapper
  open(dest,'w') do |file|
    # she-bang
    file.puts "#!" + File.join(
      RbConfig::CONFIG["bindir"],
      RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"]
    )

    # Change directory
    file.puts "Dir.chdir #{File.dirname(main).inspect}"

    # Optional data from the script (after __END__)
    file.puts DATA.read if Object.const_defined? :DATA

    # Load script
    file.puts "require #{File.basename(main).sub(/\.rb$/,'').inspect}"
  end

  # Mark wrapper as executable
  File.chmod(0755, dest)

  # Don't execute the script itself at this time
  Process.exit
end
