begin
  require 'bundler/setup'
rescue LoadError
  puts 'Although not required, bundler is recommended for running the tests.'
end

# In Ruby 1.9.2 versions before patchlevel 290, the default Psych
# parser has an issue with YAML merge keys, which 
# fixtures/mock_facebook_responses.yml relies heavily on.
# 
# Anyone using an earlier version will see missing mock response
# errors when running the test suite similar to this:
# 
# RuntimeError:
#   Missing a mock response for graph_api: /me/videos: source=[FILE]: post: with_token
#   API PATH: /me/videos?source=[FILE]&format=json&access_token=*
# 
# For now, it seems the best fix is to just downgrade to the old syck YAML parser
# for these troubled versions.
#
# See https://github.com/tenderlove/psych/issues/8 for more details
YAML::ENGINE.yamler = 'syck' if RUBY_VERSION == '1.9.2' && RUBY_PATCHLEVEL < 290

# load custom RSpec matchers
require 'support/custom_matchers'

# load the library
require 'koala'

# ensure consistent to_json behavior
# this must be required first so mock_http_service loads the YAML as expected
require 'support/ordered_hash' 
require 'support/json_testing_fix' 

# set up our testing environment
require 'support/mock_http_service'
require 'support/koala_test'
# load testing data and (if needed) create test users or validate real users
KoalaTest.setup_test_environment!

# load supporting files for our tests
require 'support/rest_api_shared_examples'
require 'support/graph_api_shared_examples'
require 'support/uploadable_io_shared_examples'

BEACH_BALL_PATH = File.join(File.dirname(__FILE__), "fixtures", "beach.jpg")