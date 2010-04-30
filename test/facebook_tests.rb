require 'test/unit'
require 'rubygems'
require 'spec/test/unit'

require 'facebook_graph'
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

# load the access token if provided
# I'm seeing a bug with spec and gets where the facebook_test_suite.rb file gets read in when gets is called
# until that's solved, we'll need to store/update tokens in the access_token file
if $access_token = File.read("fixtures/access_token") rescue nil
  puts "Got access token #{$access_token.inspect}"
else
  puts "Access token tests will fail until you store a valid token in the access_token file"
end
