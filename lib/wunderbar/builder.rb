# add indented_text!, indented_data! and traceback! methods to builder
module Builder
  class XmlMarkup
    unless method_defined? :indented_text!
      def indented_text!(text)
        indented_data!(text) {|data| text! data}
      end
    end

    unless method_defined? :indented_data!
      def indented_data!(data, &block)
        return if data.strip.length == 0

        if @indent > 0
          data.sub! /\n\s*\Z/, ''
          data.sub! /\A\s*\n/, ''

          unindent = data.sub(/s+\Z/,'').scan(/^ *\S/).map(&:length).min || 1

          before  = ::Regexp.new('^'.ljust(unindent))
          after   =  " " * (@level * @indent)
          data.gsub! before, after
        end

        if block
          block.call(data)
        else
          self << data
        end

        _newline unless data =~ /\n\Z/
      end
    end

    unless method_defined? :traceback!
      def traceback!(exception=$!, klass='traceback')
        pre :class=>klass do
          text! exception.inspect
          _newline
          exception.backtrace.each {|frame| text!((' '*@indent)+frame + "\n")}
        end
      end
    end
  end
end
