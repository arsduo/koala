require 'test/unit'
require 'rubygems'
require 'spec/test/unit'

# load the libraries
require 'koala'

# load the tests
require 'koala/api_base_tests'

require 'koala/graph_api/graph_api_no_access_token_tests'
require 'koala/graph_api/graph_api_with_access_token_tests'

require 'koala/rest_api/rest_api_no_access_token_tests'
require 'koala/rest_api/rest_api_with_access_token_tests'

require 'koala/oauth/oauth_tests'

#require 'koala/realtime_updates/realtime_updates_tests'