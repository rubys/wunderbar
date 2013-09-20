require 'wunderbar/opal-browser'

_html do
  _head do
    _title 'Opal demonstration'
  end

  _body do
    _span 0
    _button 'increment'
    _script do
      $document.at('button').on :click do
        span = $document.at('span')
        span.text = span.text.to_i+1
      end
    end
  end
end
