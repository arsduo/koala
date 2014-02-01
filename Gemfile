source "https://rubygems.org"

group :development do
  gem 'debugger'
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

platforms :rbx do
  gem 'rubysl', '~> 2.0'         # if using anything in the ruby standard library
  gem 'psych'                    # if using yaml
  gem 'rubinius-developer_tools' # if using any of coverage, debugger, profiler
end

gemspec
