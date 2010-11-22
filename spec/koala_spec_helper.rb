if defined?(RUBY_VERSION) && RUBY_VERSION =~ /1\.9/
  require 'test/unit'
  require 'rspec'

  Rspec.configure do |c|
    c.mock_with :rspec
  end
  
else
  # Ruby 1.8.x
  require 'test/unit'
  require 'rubygems'

  require 'spec/test/unit'
end

# load the libraries
require 'koala'

# load testing data libraries
require 'koala/live_testing_data_helper'
=begin
# API tests
require 'koala/api_base_tests'

require 'koala/graph_api/graph_collection_tests'
require 'koala/graph_api/graph_api_no_access_token_tests'
require 'koala/graph_api/graph_api_with_access_token_tests'

require 'koala/rest_api/rest_api_no_access_token_tests'
require 'koala/rest_api/rest_api_with_access_token_tests'

require 'koala/graph_and_rest_api/graph_and_rest_api_no_token_tests'
require 'koala/graph_and_rest_api/graph_and_rest_api_with_token_tests'

# OAuth tests
require 'koala/oauth/oauth_tests'

# Subscriptions tests
require 'koala/realtime_updates/realtime_updates_tests'

# Services tests
require 'koala/net_http_service_tests'
=end

# Test users tests
require 'koala/test_users/test_users_tests'


