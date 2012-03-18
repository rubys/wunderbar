require 'wunderbar'

Wunderbar.html do
  _head_ do
    _title 'CGI Environment'
    _style %{
      table {border-spacing: 0}
      th, td {padding: 0.2em 0.5em}
      thead th {border-bottom: solid 1px #000}
      tbody tr:nth-child(5n) td {border-bottom: solid 1px #888}
      th:last-child, td:last-child {border-left: solid 1px #000}
      tr:hover {background-color: #FF8}
    }
  end
  _body? do
    _h1 'Environment Variables'
    _table do
      _thead_ do
        _tr do
          _th 'Name'
          _th 'Value'
        end
      end
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
