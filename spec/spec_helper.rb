begin
  require 'bundler/setup'
rescue LoadError
  puts 'although not required, bundler is recommened for running the tests'
end

# load the libraries
require 'koala'

# load testing data libraries
require 'support/live_testing_data_helper'
require 'support/mock_http_service'
require 'support/rest_api_shared_examples'
require 'support/graph_api_shared_examples'


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