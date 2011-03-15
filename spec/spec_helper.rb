begin
  require 'bundler/setup'
rescue LoadError
  puts 'although not required, bundler is recommened for running the tests'
end

# load the libraries
require 'koala'

# load testing data libraries
require 'support/live_testing_data_helper'
require 'support/mock_http_service'
require 'support/rest_api_shared_examples'
require 'support/graph_api_shared_examples'
require 'support/setup_mocks_or_live'