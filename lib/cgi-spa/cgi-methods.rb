# produce json
def $cgi.json
  return unless $XHR_JSON
  $cgi.out 'type' => 'application/json', 'Cache-Control' => 'no-cache' do
    JSON.pretty_generate(yield)+ "\n"
  end
end

# produce json and quit
def $cgi.json! &block
  return unless $XHR_JSON
  json(&block)
  Process.exit
end

# produce html/xhtml
def $cgi.html
  return if $XHR_JSON
  if $XHTML
    $cgi.out 'type' => 'application/xhtml+xml', 'charset' => 'UTF-8' do
      $x.declare! :DOCTYPE, :html
      $x.html :xmlns => 'http://www.w3.org/1999/xhtml' do
        yield $x
      end
    end
  else
    $cgi.out 'type' => 'text/html', 'charset' => 'UTF-8' do
      $x.declare! :DOCTYPE, :html
      $x.html do
        yield $x
      end
    end
  end
end

# produce html and quit
def $cgi.html! &block
  return if $XHR_JSON
  html(&block)
  Process.exit
end

# post specific logic (doesn't produce output)
def $cgi.post
  yield unless $HTTP_POST
end

# post specific content (produces output)
def $cgi.post! &block
  html!(&block) unless $HTTP_POST
end
