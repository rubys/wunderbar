#!/usr/bin/ruby

# This demo provides a rough HTML => Wunderbar conversion (a more complete
# conversion tool is available in tools/web2script.rb).

require 'ruby2js/filter/functions'
require 'wunderbar/jquery'

_html do
  _style %{
    h1 {text-align: center}
    main {height: 15em; clear: both}
    textarea {width: 49%; height: 100%; color: black; background-color: white}
  }
  
  _header_ do
    _h1 'HTML to Wunderbar conversion'
    _span "HTML", style: 'float: left; margin-left: 5%'
    _span "code", style: 'float: right; margin-right: 5%'
  end

  _main_ do
    _textarea.input!
    _textarea.output! :disabled
  end

  _script do
    name_pattern = '[a-zA-Z][-a-zA-Z0-9]*'
    re_name = /^#{name_pattern}$/
    re_names = /^#{name_pattern}( #{name_pattern})*$/

    # convert children of a parent node into indented code
    def code(parent, indent='')
      result = ''
      ~parent.contents.each do |index, node|
        if node.nodeType == 1
          # start with node name
          result += "#{indent}_#{node.localName}"

          # add id attribute, if any
          if node.id and node.id =~ re_name
            result += ".#{node.id.gsub('-', '_')}!"
            ~node.removeAttr('id')
          end

          # add class attributes, if any
          if node.className and node.className =~ re_names
            node.className.split(/\s+/).each do |cname|
              result += ".#{cname.gsub('-', '_')}"
            end
            ~node.removeAttr('class')
          end

          # extract node contents and attributes
          contents = ~node.contents
          attrs = node.attributes

          # if children consists of a single text node, add to element
          if contents.length == 1 and contents[0].nodeType == 3
            result += " #{JSON.stringify(~node.text.gsub(/\s+/, ' ').trim())}"
            result += ',' if attrs.length > 0
            contents = []
          end

          # add in remaining attributes
          for i in 0...attrs.length
            result += ',' if i > 0
            if attrs[i].name =~ re_name
              result += " #{attrs[i].name.gsub('-', '_')}: "
            else
              result += " #{JSON.stringify(attrs[i].name)} => "
            end
            result += JSON.stringify(attrs[i].value)
          end

          # process children, if any
          if contents.length > 0
            result += " do\n#{code(node, "  #{indent}")}end"
          end

          result += "\n"

        elsif node.nodeType == 3
          # add in text nodes unless they consist entirely of whitespace
          unless node.textContent.trim() == ''
            text = node.textContent.gsub(/\s+/, ' ').trim()
            result += "#{indent}_ #{JSON.stringify(text)}\n"
          end
        end
      end

      return result
    end

    # update output whenever input changes
    ~'#input'.on(:input) do
      ~'#output'.val = code(~'<div></div>'.html(~'textarea'.val))
    end

    ~'#input'.trigger(:input)
  end
end
