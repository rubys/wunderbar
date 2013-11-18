require 'wunderbar'
require 'ruby2js'

# convert script blocks to JavaScript.  If binding_of_caller is available,
# full access to all variables defined in the callers scope may be made
# by execute strings (`` or %x()).

module Wunderbar
  class HtmlMarkup
    def _script(*args, &block)
      if block
        if binding.respond_to? :of_caller
          # provided by require 'binding_of_caller'
          args.unshift Ruby2JS.convert(block, binding: binding.of_caller(1))
        else
          args.unshift Ruby2JS.convert(block, binding: binding)
        end
        super *args, &nil
      else
        super
      end
    end
  end
end
