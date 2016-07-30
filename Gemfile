source 'https://rubygems.org'

gem 'json'

group :test do
  gem 'rake'
  gem 'actionpack'
  if RUBY_VERSION =~ /^1|^2.[01]/
    gem 'sinatra'
  else
    gem 'sinatra', github: 'sinatra/sinatra'
    gem 'rack-protection', github: 'sinatra/rack-protection'
  end
  gem 'nokogumbo'
  gem 'ruby2js'
  gem 'rails', '5.0.0'
  gem 'sourcify'
  gem 'coffee-script'
  gem 'kramdown'
  gem 'coderay'
  gem 'sanitize'
  gem 'minitest'

  gem 'execjs', '<2.5.1' if RUBY_VERSION =~ /^1/
  gem 'tins', '~> 1.6.0' if RUBY_VERSION =~ /^1/
end
