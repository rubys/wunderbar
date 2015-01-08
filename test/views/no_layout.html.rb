_html do
  _head_ do
    _title 'No Layout'
  end

  _body? do
    _p 'From the view'
    _p @message
  end
end
