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

platforms :rbx do
  gem 'rubysl', '~> 2.0'         # if using anything in the ruby standard library
  gem 'psych'                    # if using yaml
  gem 'rubinius-developer_tools' # if using any of coverage, debugger, profiler
end

gemspec
