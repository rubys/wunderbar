module Wunderbar
  # Extract data from the script (after __END__)
  def self.data
    data = DATA.read 

    # process argument overrides
    data.scan(/^\s*([A-Z]\w*)\s*=\s*(['"]).*\2$/).each do |name, q|
      override = ARGV.find {|arg| arg =~ /--#{name}=(.*)/i}
      data[/^\s*#{name}\s*=\s*(.*)/,1] = $1.inspect if override
    end

    data
  end
end

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
    file.puts "\n#{Wunderbar.data}\n" if Object.const_defined? :DATA

    # Load script
    if main.end_with? '.rb'
      require = "require #{"./#{File.basename(main).chomp('.rb')}".inspect}"
    else
      require = "load #{"./#{File.basename(main)}".inspect}"
    end
    if ARGV.delete('--rescue') or ARGV.delete('--backtrace')
      file.puts <<-EOF.gsub(/^ {8}/,'')
        begin
          #{require}
        rescue ::SystemExit => exception
        rescue ::Exception => exception
          print "Content-Type: text/plain\\r\\n\\r\\n"
          puts exception.inspect
          exception.backtrace.each do |frame|
            puts "  \#{frame}"
          end
        end
      EOF
    else
      file.puts require
    end
  end

  # Mark wrapper as executable
  File.chmod(0755, dest)

  # Don't execute the script itself at this time
  Process.exit
end
