begin
  require 'bundler/setup'
rescue LoadError
  puts 'although not required, bundler is recommened for running the tests'
end

# load the libraries
require 'koala'

# load testing data libraries
require 'koala/live_testing_data_helper'

# API tests
require 'koala/api_base_tests'

require 'koala/graph_api/graph_api_tests'
require 'koala/graph_api/graph_collection_tests'
require 'koala/graph_api/graph_api_no_access_token_tests'
require 'koala/graph_api/graph_api_with_access_token_tests'

require 'koala/rest_api/rest_api_tests'
require 'koala/rest_api/rest_api_no_access_token_tests'
require 'koala/rest_api/rest_api_with_access_token_tests'

require 'koala/graph_and_rest_api/graph_and_rest_api_no_token_tests'
require 'koala/graph_and_rest_api/graph_and_rest_api_with_token_tests'

# OAuth tests
require 'koala/oauth/oauth_tests'

# Subscriptions tests
require 'koala/realtime_updates/realtime_updates_tests'

# Test users tests
require 'koala/test_users/test_users_tests'

# Services tests
require 'koala/http_services/http_service_tests'
require 'koala/http_services/net_http_service_tests'
begin
  require 'koala/http_services/typhoeus_service_tests'
rescue LoadError
  puts "Typhoeus tests will not be run because Typhoeus is not installed."
end

module KoalaTest
  def self.validate_user_info(token)
    print "Validating permissions for live testing..."
    # make sure we have the necessary permissions
    api = Koala::Facebook::GraphAndRestAPI.new(token)
    uid = api.get_object("me")["id"]
    perms = api.fql_query("select read_stream, publish_stream, user_photos from permissions where uid = #{uid}")[0]
    perms.each_pair do |perm, value|
      unless value == 1
        puts "failed!\n" # put a new line after the print above
        raise ArgumentError, "Your access token must have the read_stream, publish_stream, and user_photos permissions.  You have: #{perms.inspect}"
      end
    end
    puts "done!"
  end
end