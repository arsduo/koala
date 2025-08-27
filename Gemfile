source "https://rubygems.org"

group :development do
  gem 'debugger', :platforms => [:mri_19]
  gem 'byebug', :platforms => [:mri_20, :mri_21]
  gem "yard"
end

group :development, :test do
  gem "psych", '< 4.0.0' # safe_load signature not compatible with older rubies
  gem "rake"
  gem "typhoeus" unless defined? JRUBY_VERSION
  gem 'faraday-typhoeus' unless defined? JRUBY_VERSION
end

group :test do
  gem "rspec", "~> 3.0", "< 3.10" # resrict rspec version until https://github.com/rspec/rspec-support/pull/537 gets merged
  gem "vcr", github: 'vcr/vcr', ref: 'ce35c236fe48899f02ddf780973b44cdb756c0ee' # needs https://github.com/vcr/vcr/issues/1057 for ruby 3.5
  gem "webmock"
  gem "simplecov"
end

gem "jruby-openssl" if defined? JRUBY_VERSION

gemspec
