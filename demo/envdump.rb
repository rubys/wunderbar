require 'wunderbar'

Wunderbar.html do
  _head_ do
    _title 'CGI Environment'
  end
  _body? do
    _h1 'Environment Variables'
    _table do
      _tbody do
        ENV.sort.each do |name, value|
          _tr_ do
            _td name
            _td value
          end
        end
      end
    end
  end
end
