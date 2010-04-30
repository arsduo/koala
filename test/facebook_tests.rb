require 'test/unit'
require 'rubygems'
require 'spec/test/unit'

require '../lib/facebook_graph.rb'
require 'facebook_graph/facebook_no_access_token_tests'
require 'facebook_graph/facebook_with_access_token_tests'

class FacebookTestSuite
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << FacebookNoAccessTokenTests.suite
    suite << FacebookWithAccessTokenTests.suite
    #suite << FacebookCookieTest.suite
    suite
  end
end

# load testing data (see note in readme.md)
# I'm seeing a bug with spec and gets where the facebook_test_suite.rb file gets read in when gets is called
# until that's solved, we'll need to store/update tokens in the access_token file
$testing_data = YAML.load_file("facebook_data.yml") rescue {}

unless $testing_data["oauth_token"]
  puts "Access token tests will fail until you store a valid token in facebook_data.yml"
end
unless cookies = $testing_data["cookie_hash"]
  puts "Cookie tests will fail until you store a valid token in facebook_data.yml"
end