begin
  require 'bundler/setup'
rescue LoadError
  puts 'Although not required, bundler is recommended for running the tests.'
end

# load the library
require 'koala'

# set up our testing environment
require 'support/mock_http_service'
# ensure consistent to_json behavior
require 'support/json_testing_fix' 
require 'support/koala_test'
# load testing data and (if needed) create test users or validate real users
KoalaTest.setup_test_environment!

# load supporting files for our tests
require 'support/rest_api_shared_examples'
require 'support/graph_api_shared_examples'
require 'support/uploadable_io_shared_examples'

BEACH_BALL_PATH = File.join(File.dirname(__FILE__), "fixtures", "beach.jpg")