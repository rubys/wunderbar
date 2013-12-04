# based on http://docs.angularjs.org/tutorial

require 'wunderbar/sinatra'
require 'wunderbar/angular/route'
require 'wunderbar/angular/resource'

get '/' do
  _html :index
end

# allow path to override 'views'
helpers do
  def find_template(view, name, engine, &block)
    view = Sinatra::Application.root unless File.dirname(name.to_s) == '.'
    super(view, name, engine, &block)
  end
end

# define routes to everything in the partials directory
Dir['partials/*'].each do |partial|
  partial = partial.chomp(File.extname(partial))
  get "/#{partial}.html" do
    _html partial.to_sym
  end
end

# define routes to everything in the js directory
Dir['js/*'].each do |js|
  js = js.chomp(File.extname(js))
  get "/#{js}.js" do
    _js js.to_sym
  end
end
