source 'https://rubygems.org'

gem 'json'

group :test do
  gem 'rake'
  if RUBY_VERSION =~ /^1|^2.[01]/
    gem 'sinatra', '~> 1.4'
  else
    gem 'actionpack'
    gem 'sinatra', github: 'sinatra/sinatra'
    gem 'rack-protection', github: 'sinatra/rack-protection'
    gem 'rails', '5.0.0'
  end
  gem 'nokogumbo'
  gem 'ruby2js'
  gem 'sourcify'
  gem 'coffee-script'
  gem 'kramdown'
  gem 'coderay'
  gem 'sanitize'
  gem 'minitest'

  gem 'execjs', '<2.5.1' if RUBY_VERSION =~ /^1/
  gem 'tins', '~> 1.6.0' if RUBY_VERSION =~ /^1/
end
