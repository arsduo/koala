require 'test/unit'
require 'rubygems'
require 'spec/test/unit'

require '../src/facebook'
require 'facebook_no_access_token_tests'


class FacebookTestSuite
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << FacebookNoAccessTokenTests.suite
    #suite << FacebookAccessToken.suite
    #suite << FacebookCookieTest.suite
    suite
  end
end
Test::Unit::UI::Console::TestRunner.run(FacebookTestSuite)