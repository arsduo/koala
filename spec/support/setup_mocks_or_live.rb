# small helper method for live testing
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


if ENV['LIVE']
  # Runs Koala specs through the Facebook servers
  #
  # Note that you need a valid OAuth token and code for these
  # specs to run.  See facebook_data.yml for more information.

  # load testing data (see note in readme.md)
  $testing_data = YAML.load_file(File.join(File.dirname(__FILE__), 'fixtures/facebook_data.yml')) rescue {}

  unless $testing_data["oauth_token"]
    puts "Access token tests will fail until you store a valid token in facebook_data.yml"
  end

  unless $testing_data["oauth_test_data"] && $testing_data["oauth_test_data"]["code"] && $testing_data["oauth_test_data"]["secret"]
    puts "OAuth code tests will fail until you store valid data for the user's OAuth code and the app secret in facebook_data.yml"
  end

  KoalaTest.validate_user_info $testing_data["oauth_token"]
end