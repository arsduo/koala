source :rubygems

group :development do
  gem "yard"
end

group :development, :test do
  gem "typhoeus" unless defined? JRUBY_VERSION

  # Testing infrastructure
  gem 'guard'
  gem 'guard-rspec'
  gem "parallel_tests"

  if RUBY_PLATFORM =~ /darwin/
    # OS X integration
    gem "ruby_gntp"
    gem "rb-fsevent", "~> 0.4.3.1"
  end
end

gem "jruby-openssl" if defined? JRUBY_VERSION

gemspec
