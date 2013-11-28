require 'rubygems'
require 'optparse'
require 'wunderbar'
require 'net/http'

# Convert a webpage to a Wunderbar script

$header = true

OptionParser.new { |opts|
  opts.banner = "#{File.basename(__FILE__)} [-o output] [-w width] URLs..."
  opts.on '-o', '--output FILE', 'Send Output to FILE' do |file|
    $stdout = File.open(file, 'w')
  end
  opts.on '-w', '--width WIDTH', Integer, 'Set line width' do |width|
    $width = width
  end
  opts.on '-g', '--group lines', Integer, 
    'Insert blanks lines around blocks larger than this value' do |group|
    $group = group
  end
  opts.on '-f', '--[no-]fragment', '-p', '--[no-]partial',  
    'Output as a fragment / partial' do |fragment|
    $fragment = fragment
  end
  opts.on '-h', '--[no-]header',  'Output program header' do |header|
    $header = header
  end
  opts.on '-h', 'Omit program header' do |header|
    $header = false
  end
  if ''.respond_to? 'encoding'
    opts.on '-a', '--ascii', Integer, 'Escape non-ASCII characters' do
      $ascii = true
    end
  end
  opts.on '-x', '--xhtml', 'Output as XHTML' do
    $xhtml = true
  end
}.parse!

# prefer nokogumbo / gumbo-parser, fallback to nokogiri / lixml2
begin
  require 'nokogumbo'
  $namespaced = {}
rescue LoadError 
  require 'nokogiri'
  module Nokogiri
    module HTML5
      def self.get(uri)
        doc = Net::HTTP.get(uri)
        $namespaced = Hash[doc.scan(/<\/(\w+):(\w+)>/).uniq.
          map {|p,n| [n, "#{p} :#{n}"]}]
        $namespaced.delete_if {|name, value| doc =~ /<#{name}[ >]/}
        Nokogiri::HTML(doc)
      end
    end
  end
end

# Method to "enquote" a string
class String
  def enquote
    if $ascii
      inspect.gsub(/[^\x20-\x7f]/) { |c| '\u' + c.ord.to_s(16).rjust(4,'0') }
    else
      inspect
    end
  end
end

# queue of lines to be output
$q = []
def q line
  $q << line
end

def flow_text(line, join)
  while $width and line.length>$width
    line.sub! /(.{#{join.length}},#{$width-4}})(\s+|\Z)/, "\\1 #{join}"
    break unless line.include? "\n"
    q line.split("\n").first
    line = line[/\n(.*)/,1]
  end
  q line
end

def flow_attrs(line, attributes, indent)
  attributes.each do |attribute|
    line += ','
    if $width and (line+attribute).length > $width-1
      q line
      line = "#{indent} "
    end
    line += attribute
  end
  q line
end

ITEMS = %w{
  button dd dt figcaption h1 h2 h3 h4 h5 h6 input label
  legend li meter option output progress td th title
}

def code(element, indent='', flat=false)
  element_name = element.name

  # fixup namespaces
  if element_name =~ /^(\w+)(:\w+)$/
    # split qname and element name in Nokogumbo parsed output
    element_name = "#{$1} #{$2}" 
    element_name += ',' unless element.attributes.empty?
  elsif $namespaced[element.name]
    # restore namespaces that Nokogiri::HTML dropped
    element_name = $namespaced[element.name]
    element_name += ',' unless element.attributes.empty?
  end

  element['_width'] ||= $width if $width and element_name == 'html'
  element_name = 'xhtml' if $xhtml and element_name == 'html'

  # drop meta content-type and charset elements
  if element_name == 'meta'
    return if element['http-equiv'].to_s.downcase == 'content-type'
    return if element['charset']
  end

  attributes = []
  element.attributes.each do |key, value|
    value = value.to_s

    # resolve relative links
    if %w(a img link script).include? element.name and %w(href src).include? key
      value = ($uri + value).to_s rescue value
    end

    if ITEMS.include? element.name and element.text.end_with? "\n"
      unless element.children.any? {|child| child.element?}
        element.content = element.text.chomp
      end
    end

    if key =~ /^\w+$/
      if key == 'id' and value =~ /^\w+$/
        element_name += ".#{value}!"
      elsif key == 'class' and value =~ /^\w+$/
        element_name += ".#{value}"
      elsif key == 'xmlns' and %w(html svg mathml).include? element.name
        # drop xmlns attributes from these elements
      elsif key == 'type' and element.name == 'style' and value == 'text/css'
        # drop type attributes from script elements
      elsif key == 'type' and element.name == 'script' and value == 'text/javascript'
        # drop type attributes from script elements
      elsif RUBY_VERSION =~ /^1\.8/
        attributes << " :#{key} => #{value.enquote}"
      else
        attributes << " #{key}: #{value.enquote}"
      end
    else
      attributes << " #{key.enquote} => #{value.enquote}"
    end
  end

  line = "#{indent}_#{element_name}#{attributes.join(',')}"

  if element.children.empty?
    return if element_name == 'head' and attributes.length == 0
    flow_attrs "#{indent}_#{element_name}#{attributes.pop}", attributes, indent

  # element has children
  elsif element.children.any? {|child| child.element?}
    # do any of the text nodes need special processing to preserve spacing?
    flatten = flat || Wunderbar::HtmlMarkup.flatten?(element.children)
    line.sub! /(\w)( |\.|$)/, '\1!\2' if flatten and not flat

    skip = $fragment
    skip = false unless %w(html head body).include? element_name
    skip = false unless element.attributes.length == 0

    if skip
      cindent = indent
    else
      q "#{line} do"
      cindent = "#{indent}  "
    end

    start = $q.length
    blank = false
    first = true
    breakable = $group && !flat && !element.children.any? do |child| 
      child.text? and not child.text.strip.empty?
    end

    # recursively process children
    element.children.each do |child|
      if child.text? or child.cdata?
        text = child.text.gsub(/\s+/, ' ')
        text = text.strip unless flatten
        next if text.empty?
        flow_text "#{cindent}_ #{text.enquote}", "\" +\n    #{indent}\""
        first = true # stop break
      elsif child.comment?
        flow_text "#{cindent}_.comment! #{child.text.strip.enquote}", 
          "\" +\n    #{indent}\""
      else
        code(child, cindent, flatten)
      end

      # insert a blank line if either this or the previous block was large
      if $group and start + $group < $q.length
        $q[start].sub! /^(\s+_\w+)([! .])/, '\1_\2' if breakable
        $q.insert(start,'') if not first
        blank = !child.text?
      else
        $q.insert(start,'') if blank
        blank = false
      end
      first = (start == $q.length)
      start = $q.length
    end

    q indent + "end" unless skip

  elsif element.name == 'pre' and element.text.include? "\n"
    data = element.text.sub(/\A\n/,'').sub(/\s+\Z/,'')

    unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1
    before  = Regexp.new('^'.ljust(unindent))
    after   =  "#{indent}  "
    data.gsub! before, after

    flow_attrs "#{indent}_pre <<-EOD.gsub(/^\\s{#{after.length}}/,'')", 
      attributes, indent
    data.split("\n").each { |line| q line }
    q "#{indent}EOD"

  # element has text but no attributes or children
  elsif attributes.empty?
    if %w(script style).include? element.name and element.text.include? "\n"
      script = element.text.sub(/\A\n/,'').sub(/\s+\Z/,'')

      unindent = script.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1
      before  = Regexp.new('^'.ljust(unindent))
      after   =  "#{indent}  "
      script.gsub! before, after

      [ ['{','}'], ['[',']'], ['(',')'], nil ].each do |open, close|
        if open
          # properly matched?
          count = low = 0
          script.scan(Regexp.new "\\#{open}|\\#{close}") do |c| 
            count += (c==open)? 1 : -1
            low = count if count < low
          end

          if count == 0 and low == 0 and not script =~ /\\[#{open}|#{close}]/
            if script.include? '\\' or script.include? '#{'
              open = "q#{open}"
              script.gsub!(0x5C.chr*2) {|c| c+c} # \\ => \\\\
            end

            q "#{line} %#{open}"
            script.split("\n").each { |line| q line }
            q "#{indent}#{close}"
            break
          end
        else
          mark = element.name.upcase
          mark = ('A'..'Z').to_a.shuffle.join while script.include? "_#{mark}_"
          q "#{line} <<-_#{mark}_"
          script.split("\n").each { |line| q line }
          q "#{indent}_#{mark}_"
        end
      end
    else
      flow_text "#{line} #{element.text.enquote}", "\" +\n  #{indent}\""
    end

  # element has text and attributes but no children
  else
    flow_attrs "#{indent}_#{element_name} #{element.text.enquote}",
      attributes, indent
  end
end

# fetch and convert each web page
ARGV.each do |arg|
  if arg =~ %r{^https?://}
    $uri = URI.parse arg
    code Nokogiri::HTML5.get($uri).root
  else
    $uri = "file://#{arg}"
    code Nokogiri::HTML5(File.read(arg)).root
  end
end

if $headers
  # she-bang
  puts "#!" + File.join(
    RbConfig::CONFIG["bindir"],
    RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"]
  )

  # headers
  if RUBY_VERSION =~ /^1\.8/
    puts "require 'rubygems'"
  elsif RUBY_VERSION =~ /^1/
    puts '# encoding: utf-8' if $q.any? {|line| line.match /[^\x20-\x7f]/}
  end

  puts "require 'wunderbar'\n\n"
end

# main output
puts $q.join("\n")

# make executable
$stdout.chmod($stdout.stat.mode&0755|0111) if $stdout.respond_to? :chmod
