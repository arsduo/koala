source "https://rubygems.org"

group :development do
  gem 'debugger'
  gem "yard"
end

group :development, :test do
  gem "rake"
  gem "typhoeus" unless defined? JRUBY_VERSION
end

group :test do
  gem "rspec", '~> 3.0.0.beta1'
end

gem "jruby-openssl" if defined? JRUBY_VERSION

gemspec
