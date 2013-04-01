source "https://rubygems.org"

group :development do
  gem "yard"
end

group :development, :test do
  gem "typhoeus" unless defined? JRUBY_VERSION

  # Testing infrastructure
  gem 'guard'
  gem 'guard-rspec'

  if RUBY_PLATFORM =~ /darwin/
    # OS X integration
    gem "ruby_gntp"
    gem "rb-fsevent"
  end
end

gem "jruby-openssl" if defined? JRUBY_VERSION

gemspec
