source 'https://rubygems.org'

gem 'json', ('~> 1.8' if RUBY_VERSION < '2')

group :test do
  gem 'rake'

  if RUBY_VERSION =~ /^1|^2\.0/
    gem 'nokogiri', '~> 1.6.8'
    gem 'nokogumbo'
  else
    gem 'nokogiri'
  end

  if RUBY_VERSION =~ /^1|^2\.[01]/
    gem 'sinatra', '~> 1.4'
  else
    gem 'sinatra', '~> 2.0'
    unless RUBY_VERSION =~ /^2\.[2345]/
      gem 'rails', '~> 6.0'
    end
  end

  gem 'ruby2js'
  gem 'sourcify'
  gem 'coffee-script'

  if RUBY_VERSION =~ /^1/
    gem 'kramdown', '~> 1.14.0'
  else
    gem 'kramdown'
  end

  gem 'coderay'
  gem 'sanitize'
  gem 'minitest'

  gem 'execjs', '<2.5.1' if RUBY_VERSION =~ /^1/
  gem 'tins', '~> 1.6.0' if RUBY_VERSION =~ /^1/
end
