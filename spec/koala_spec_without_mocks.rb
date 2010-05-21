require 'koala_spec_helper'

# Runs Koala specs through the Facebook servers
#
# Note that you need a valid OAuth token and code for these
# specs to run.  See facebook_data.yml for more information.

# load testing data (see note in readme.md)
# I'm seeing a bug with spec and gets where the facebook_test_suite.rb file gets read in when gets is called
# until that's solved, we'll need to store/update tokens in the access_token file
$testing_data = YAML.load_file(File.join(File.dirname(__FILE__), 'facebook_data.yml')) rescue {}

unless $testing_data["oauth_token"]
  puts "Access token tests will fail until you store a valid token in facebook_data.yml"
end

unless $testing_data["oauth_test_data"] && $testing_data["oauth_test_data"]["code"] && $testing_data["oauth_test_data"]["secret"]
  puts "Cookie tests will fail until you store valid data for the cookie hash, app_id, and app secret in facebook_data.yml"
end