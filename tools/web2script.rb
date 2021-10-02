require 'rubygems'
require 'optparse'
require 'wunderbar'
require 'net/http'

# Convert a webpage to a Wunderbar script

$header = true

$option_parser = OptionParser.new do |opts|
  $width = nil
  $xhtml = nil
  $fragment = nil
  $group = nil

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
end

# prefer nokogumbo / gumbo-parser, fallback to nokogiri / lixml2
begin
  $namespaced = {}
  if RUBY_VERSION =~ /^1|^2\.0/
    require 'nokogumbo'
  else
    require 'nokogiri'
  end
rescue LoadError 
  require 'nokogiri'
  module Nokogiri
    def self.HTML5(string)
      HTML(string)
    end
  end
end

# Method to "enquote" a string
class String
  def enquote
    if match(/\A[\x20-\x26\x28-\x5b\x5d-\x7f]*\Z/) # 0x27=', 0x5c=\
      "'#{to_s}'"
    elsif $ascii
      inspect.gsub(/[^\x20-\x7f]/) { |c| '\u' + c.ord.to_s(16).rjust(4,'0') }
    else
      inspect
    end
  end
end

# from https://github.com/kangax/html-minifier/blob/gh-pages/src/htmlminifier.js
BOOLATTRS = %w(allowfullscreen async autofocus checked compact declare default
  defer disabled formnovalidate hidden inert ismap itemscope multiple muted
  nohref noresize noshade novalidate nowrap open readonly required reversed
  seamless selected sortable truespeed typemustmatch)

# queue of lines to be output
$q = []
def q line
  $q << line
end

def flow_text(line, text, indent)
  text = text.gsub(/\s+/, ' ').enquote
  line = "#{line} #{text}"
  while $width and line.length>$width
    join = "#{text[0]} +\n  #{indent}#{text[-1]}"
    line.sub!(/(.{#{join.length},#{$width-4}})(\s+|\Z)/, "\\1 #{join}")
    break unless line.include? "\n"
    q line.split("\n").first
    line = line[/\n(.*)/,1]
  end
  line
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
  line
end

ITEMS = %w{
  button dd dt figcaption h1 h2 h3 h4 h5 h6 input label
  legend li meter option output progress td th title
}

IDENTIFIER = /^[a-zA-Z][-A-Za-z0-9]*( [a-zA-Z][-A-Za-z0-9]*)*$/

def web2script(element, indent='', flat=false)
  element_name = element.name.gsub('-', '_')

  # fixup namespaces
  if element_name !~ /^[a-zA-Z]\w*$/
    element_name = ".tag! #{element_name.enquote}" 
    element_name += ',' unless element.attributes.empty?
  elsif $namespaced[element.name]
    # restore namespaces that Nokogiri::HTML dropped
    element_name = $namespaced[element.name]
    element_name += ',' unless element.attributes.empty?
  end

  element[:_width] ||= $width if $width and element_name == 'html'
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

    if key =~ /^[_a-zA-Z][-A-Za-z0-9]*$/
      key = key.gsub('-', '_')
      if key == 'id' and value =~ IDENTIFIER
        element_name += ".#{value.gsub('-','_').gsub(' ', '.')}!"
      elsif key == 'class' and value =~ IDENTIFIER
        element_name += ".#{value.gsub('-','_').gsub(' ', '.')}"
      elsif key == 'xmlns' and %w(html svg mathml).include? element.name
        # drop xmlns attributes from these elements
      elsif key == 'type' and element.name == 'style' and value == 'text/css'
        # drop type attributes from script elements
      elsif key == 'type' and element.name == 'script' and value == 'text/javascript'
        # drop type attributes from script elements
      elsif (key == value or value == '') and (BOOLATTRS.include? key or key.include? '_')
        attributes.unshift " :#{key}"
      elsif RUBY_VERSION =~ /^1\.8/
        attributes << " :#{key} => #{value.enquote}"
      else
        attributes << " #{key}: #{value.enquote}"
      end
    else
      attributes << " #{key.enquote} => #{value.enquote}"
    end
  end

  if element.children.empty?
    return if element_name == 'head' and attributes.length == 0
    q flow_attrs "#{indent}_#{element_name}#{attributes.shift}", 
      attributes, indent

  # element has children
  elsif element.children.any? {|child| child.element?}
    line = flow_attrs "#{indent}_#{element_name}#{attributes.shift}", 
      attributes, indent

    # do any of the text nodes need special processing to preserve spacing?
    flatten = flat || Wunderbar::HtmlMarkup.flatten?(element.children)
    line.sub!(/(\w)( |\.|$)/, '\1!\2') if flatten and not flat

    skip = $fragment
    skip = false unless %w(html head body).include? element_name
    skip = false unless element.attributes.length == 0

    if skip
      cindent = indent
    else
      q "#{line} do"
      cindent = "#{indent}  "
    end

    baseline = start = $q.length
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
        q flow_text "#{cindent}_", text, cindent
        first = true # stop break
      elsif child.comment?
        q flow_text "#{cindent}_.comment!",  child.text.strip, cindent
      else
        web2script(child, cindent, flatten)
      end

      # insert a blank line if either this or the previous block was large
      if $group and start + $group < $q.length
        $q[start].sub!(/^(\s+_\w+)([! .])/, '\1_\2') if breakable
        $q.insert(start,'') if not first
        blank = !child.text?
      else
        $q.insert(start,'') if blank
        blank = false
      end
      first = (start == $q.length)
      start = $q.length
    end

    if ITEMS.include? element.name and element.attributes.empty?
      if $q.length == baseline + 1
        if not $width or ($q[-2] + $q[-1].strip).length < $width-2
          line = $q[-2].sub(/do$/, '{ ') + $q[-1].strip + ' }'
          $q.pop(2)
          $q.push(line)
          skip = true
        end
      end
    end

    q indent + "end" unless skip

  elsif %w(pre code).include? element.name and element.text.include? "\n"
    data = element.text.sub(/\A\n/,'').sub(/\s+\Z/,'')

    unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1
    before  = Regexp.new('^'.ljust(unindent))
    after   =  "#{indent}  "
    data.gsub! before, after

    q "#{indent}_#{element.name} <<-EOD.gsub(/^\\s{#{after.length}}/,'')" +
      attributes.map {|attr| ", #{attr}"}.join
    data.split("\n").each { |dline| q dline }
    q "#{indent}EOD"

  # element has text but no attributes or children
  elsif attributes.empty?
    line = "#{indent}_#{element_name}"

    if %w(script style).include? element.name and element.text.include? "\n"
      script = element.text.sub(/\A\s*\n/,'').sub(/\s+\Z/,'')
      script.gsub!(/^\t+/) {|tabs| ' ' * 8 * tabs.length}

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
            script.split("\n").each { |sline| q sline }
            q "#{indent}#{close}"
            break
          end
        else
          mark = element.name.upcase
          mark = ('A'..'Z').to_a.shuffle.join while script.include? "_#{mark}_"
          q "#{line} <<-_#{mark}_"
          script.split("\n").each { |sline| q sline }
          q "#{indent}_#{mark}_"
        end
      end
    else
      text = flat ? element.text : element.text.strip
      q flow_text line, text, indent
    end

  # pre, script with attributes
  elsif %w(pre script).include? element_name
    line = flow_attrs "#{indent}_#{element_name}#{attributes.pop}", 
      attributes, indent
    data = element.text.sub(/\A\n/,'').sub(/\s+\Z/,'')

    q "#{line} do"
    q "#{indent}  _! <<-EOD"
    data.split("\n").each {|dline| q dline}
    q "#{indent}  EOD"
    q "#{indent}end"

  # element has text and attributes but no children
  else
    line = flow_text "#{indent}_#{element_name}", element.text, indent
    q flow_attrs line, attributes, indent
  end
end

if __FILE__ == $0
  $option_parser.parse!

  # fetch and convert each web page
  ARGV.each do |arg|
    if arg =~ %r{^https?://}
      $uri = URI.parse arg
      doc = Net::HTTP.get($uri)
      $namespaced = Hash[doc.scan(/<\/(\w+):(\w+)>/).uniq.
        map {|p,n| [n, ".tag! #{"#{p}:#{n}".enquote}"]}]
      $namespaced.delete_if {|name, value| doc =~ /<#{name}[ >]/}
      web2script Nokogiri::HTML5(doc).root
    else
      $uri = "file://#{arg}"
      web2script Nokogiri::HTML5(File.read(arg)).root
    end
  end

  if $header
    # she-bang
    puts "#!" + File.join(
      RbConfig::CONFIG["bindir"],
      RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"]
    )

    # headers
    if RUBY_VERSION =~ /^1\.8/
      puts "require 'rubygems'"
    elsif RUBY_VERSION =~ /^1/
      puts '# encoding: utf-8' if $q.any? {|line| line.match(/[^\x20-\x7f]/)}
    end

    puts "require 'wunderbar'\n\n"
  end

  # main output
  puts $q.join("\n")

  # make executable
  $stdout.chmod($stdout.stat.mode&0755|0111) if $stdout.respond_to? :chmod
end
