require 'wunderbar/jquery'
require 'ruby2js/filter/jquery'

# Convert Wunderbar html syntax into JQuery calls

module Wunderbar
  module Filter
    module JQuery
      include Ruby2JS::Filter::SEXP

      def on_send(node)
        return super if @react

        if node.children[0] == nil and node.children[1] =~ /^_\w/
          # map method calls starting with an underscore to jquery calls
          # to create an element.  
          #
          # input:
          #   _a 'name', href: 'link'
          # output:
          #  $('<a></a>').text('name').attr(href: 'link')
          #
          tag = node.children[1].to_s[1..-1]
          if Node::VOID.include? tag
            element = s(:send, s(:str, "<#{tag}/>"), :~) 
          else
            element = s(:send, s(:str, "<#{tag}></#{tag}>"), :~) 
          end
          node.children[2..-1].each do |child|
            if child.type == :hash
              # convert _ to - in attribute names
              pairs = child.children.map do |pair|
                key, value = pair.children
                if key.type == :sym
                  s(:pair, s(:str, key.children[0].to_s.gsub('_', '-')), value)
                else
                  pair
                end
              end

              element = s(:send, element, :attr, s(:hash, *pairs))

            elsif child.type == :addClass
              # :addClass arguments are inserted by "css proxy" logic below
              element = s(:send, element, :addClass, s(:sym, *child.children))

            elsif child.type == :block
              # :block arguments are inserted by on_block logic below
              element = s(:block, s(:send, element, :each!), 
                *node.children.last.children[1..-1])

            else
              # everything else added as text
              element = s(:send, element, :text, child)

            end
          end

          begin
            jqchild, @_jqchild = @_jqchild, true

            # have nested elements append themselves to their parent
            if jqchild
              element = s(:send, element, :appendTo, 
                s(:send, s(:lvar, :_parent), :~))
            end

            process element
          ensure
            @_jqchild = jqchild
          end

        elsif node.children[0] and node.children[0].type == :send
          # determine if markaby style class and id names are being used
          child = node
          test = child.children.first
          while test and test.type == :send and not test.is_method?
            child, test = test, test.children.first
          end

          if child.children[0] == nil and child.children[1] =~ /^_\w/
            # capture the arguments provided on the current node
            children = node.children[2..-1]

            # convert method calls to id and class values
            prefix = []
            while node != child
              if node.children[1] !~ /!$/
                # add class (mapping underscores to dashes)
                prefix.unshift s(:addClass, node.children[1].to_s.gsub('_','-'))
              else
                # convert method name to hash {id: name} pair
                pair = s(:pair, s(:sym, :id), 
                  s(:str, node.children[1].to_s[0..-2].gsub('_','-')))

                # if a hash argument is already passed, merge in id value
                hash = children.find_index {|node| node.type == :hash}
                if hash
                  children[hash] = s(:hash, pair, *children[hash].children)
                else
                  prefix.unshift s(:hash, pair)
                end
              end

              # advance to next node
              node = node.children.first
            end

            # collapse series of method calls into a single call
            return process(s(:send, *node.children[0..1], *prefix, *children))
          else
            super
          end

        else
          super
        end
      end

      def on_block(node)
        return super unless node.children[1].children.empty?
        return super if @react

        # traverse through potential "css proxy" style method calls
        child = node.children.first
        test = child.children.first
        while test and test.type == :send and not test.is_method?
          child, test = test, test.children.first
        end

        # append block as a standalone proc to wunderbar style method call
        if child.children[0] == nil and child.children[1] =~ /^_\w/
          block = s(:block, s(:send, nil, :proc), 
            s(:args, s(:arg, :_index), s(:arg, :_parent)),
            *node.children[2..-1])
          return on_send s(:send, *node.children.first.children, block)
        end

        super
      end
    end

    Ruby2JS::Filter::DEFAULTS.push JQuery
  end
end
