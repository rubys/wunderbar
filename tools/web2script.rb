require 'net/http'
require 'rubygems'
require 'nokogiri'
require 'optparse'
require 'wunderbar'

# Convert a webpage to a Wunderbar script

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
  if ''.respond_to? 'encoding'
    opts.on '-a', '--ascii', Integer, 'Escape non-ASCII characters' do
      $ascii = true
    end
  end
}.parse!

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
    line.sub! /(.{1,#{$width-4}})(\s+|\Z)/, "\\1 #{join}"
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

def code(element, indent='')
  # restore namespaces that Nokogiri::HTML dropped
  element_name = element.name
  if $namespaced[element.name]
    element_name = $namespaced[element.name]
    element_name += ',' unless element.attributes.empty?
  end

  attributes = []
  element.attributes.keys.each do |key|
    value = element[key]

    # resolve relative links
    if %w(a img link).include? element.name and %w(href src).include? key
      value = ($uri + value).to_s rescue nil
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

    # add _width to html element
    if $width and element_name == 'html'
      if RUBY_VERSION =~ /^1\.8/
        attributes << " :_width => #{$width}"
      else
        attributes << " _width: #{$width}"
      end
    end
  end

  line = "#{indent}_#{element_name}#{attributes.join(',')}"

  if element.children.empty?
    flow_attrs "#{indent}_#{element_name}#{attributes.pop}", attributes, indent

  # element has children
  elsif element.children.any? {|child| child.element?}
    # do any of the text nodes need special processing to preserve spacing?
    flatten = HtmlMarkup.flatten?(element.children)
    line.sub! /(\w)( |\.|$)/, '\1!\2' if flatten

    q "#{line} do"

    start = $q.length
    blank = false
    first = true

    # recursively process children
    element.children.each do |child|
      if child.text? or child.cdata?
        text = child.text.gsub(/\s+/, ' ')
        text = text.strip unless flatten
        next if text.empty?
        method = (text.include? '<' or text.include? '&') ? '_?' : '_'
        flow_text "#{indent}  #{method} #{text.enquote}", 
          "\" +\n    #{indent}\""
      elsif child.comment?
        flow_text "#{indent}  _.comment #{child.text.strip.enquote}", 
          "\" +\n    #{indent}\""
      else
        code(child, indent + '  ')
      end

      # insert a blank line if either this or the previous block was large
      if $group and start + $group < $q.length
        $q[start].sub! /^(\s+_\w+)([ .])/, '\1_\2'
        $q.insert(start,'')  if not first
        blank = true
      else
        $q.insert(start,'') if blank
        blank = false
      end
      start = $q.length
      first = false
    end
    q indent + "end"

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

      q "#{line} %{"
      script.split("\n").each { |line| q line }
      q "#{indent}}"
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
  $uri = URI.parse arg
  doc = Net::HTTP.get($uri)
  $namespaced = Hash[doc.scan(/<\/(\w+):(\w+)>/).uniq.
    map {|p,n| [n, "#{p} :#{n}"]}]
  $namespaced.delete_if {|name, value| doc =~ /<#{name}[ >]/}
  code Nokogiri::HTML(doc).root
end

# headers
if ''.respond_to? 'encoding'
  puts '# encoding: utf-8' if $q.any? {|line| line.match /[^\x20-\x7f]/}
else
  puts "require 'rubygems'"
end

puts "require 'wunderbar'\n\n"

# main output
puts $q.join("\n")
