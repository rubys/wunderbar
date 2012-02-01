# add indented_text!, indented_data! and traceback! methods to builder
module Builder
  class XmlMarkup
    unless method_defined? :indented_text!
      def indented_text!(text)
        indented_data!(text) {|data| text! data}
      end
    end

    unless method_defined? :indented_data!
      def indented_data!(data)
        return if data.strip.length == 0
        data.sub! /\n\s*\Z/, ''
        data.sub! /\A\s*\n/, ''
        unindent = data.sub(/s+\Z/,'').scan(/^ +/).map(&:length).min || 0

        before  = Regexp.new('^'.ljust(unindent+1))
        after   =  " " * (@level * @indent)
        data.gsub! before, after

        if block_given?
          yield data 
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

# monkey patch to ensure that tags are closed
test = 
  Builder::XmlMarkup.new.html do |x|
    x.body do
     begin
       x.p do
         raise Exception.new('boom')
       end
     rescue Exception => e
       x.pre e
     end
    end
  end

if test.index('<p>') and !test.index('</p>')
  module Builder
    class XmlMarkup
      def method_missing(sym, *args, &block)
          text = nil
        attrs = nil
        sym = "#{sym}:#{args.shift}" if args.first.kind_of?(Symbol)
        args.each do |arg|
          case arg
          when Hash
            attrs ||= {}
            attrs.merge!(arg)
          else
            text ||= ''
            text << arg.to_s
          end
        end
        if block
          unless text.nil?
            raise ArgumentError, "XmlMarkup cannot mix a text argument with a block"
          end
          _indent
          _start_tag(sym, attrs)
          _newline
          begin ### Added
            _nested_structures(block)
          ensure ### Added
            _indent
            _end_tag(sym)
            _newline
          end ### Added
        elsif text.nil?
          _indent
          _start_tag(sym, attrs, true)
          _newline
        else
          _indent
          _start_tag(sym, attrs)
          text! text
          _end_tag(sym)
          _newline
        end
        @target
      end
    end
  end
end
