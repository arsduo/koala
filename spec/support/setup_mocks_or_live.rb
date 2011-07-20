# small helper method for live testing
module KoalaTest
  def self.setup_test_user
    test_user_api = Koala::Facebook::TestUsers.new(:app_id => $testing_data["app_id"], :secret => $testing_data["secret"])
    live_testing_user = test_user_api.create(true, "read_stream, publish_stream, user_photos, user_videos, read_insights")
    $testing_data["oauth_token"] = live_testing_user["access_token"]
  end

  def self.validate_user_info(token)
    print "Validating permissions for live testing..."
    # make sure we have the necessary permissions
    api = Koala::Facebook::GraphAndRestAPI.new(token)
    perms = api.fql_query("select read_stream, publish_stream, user_photos, user_videos, read_insights from permissions where uid = me()")[0]
    perms.each_pair do |perm, value|
      if value == (perm == "read_insights" ? 1 : 0) # live testing depends on insights calls failing 
        puts "failed!\n" # put a new line after the print above
        raise ArgumentError, "Your access token must have the read_stream, publish_stream, and user_photos permissions, and lack read_insights.  You have: #{perms.inspect}"
      end
    end
    puts "done!"
  end
end


unless ENV['LIVE']
  # By default the Koala specs are run using stubs for HTTP requests
  #
  # Valid OAuth token and code are not necessary to run these
  # specs.  Because of this, specs do not fail due to Facebook
  # imposed rate-limits or server timeouts.
  #
  # However as a result they are more brittle since
  # we are not testing the latest responses from the Facebook servers.
  # Therefore, to be certain all specs pass with the current
  # Facebook services, run koala_spec_without_mocks.rb.
  Koala.http_service = Koala::MockHTTPService

  $testing_data = Koala::MockHTTPService::TEST_DATA
else
  # Runs Koala specs through the Facebook servers
  #
  # load testing data (see note in readme.md)
  $testing_data = YAML.load_file(File.join(File.dirname(__FILE__), '../fixtures/facebook_data.yml'))

  # use a test user unless the developer wants to test against a real profile
  unless $testing_data["oauth_token"]
    KoalaTest.setup_test_user
  else
    KoalaTest.validate_user_info($testing_data["oauth_token"])
  end
end

# set up a global before block to set the token for tests
# set the token up for 
Spec::Runner.configure do |config|
  config.before :each do
    @token = $testing_data["oauth_token"]
  end
end


