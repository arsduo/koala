# small helper method for live testing
module KoalaTest
  
  class << self
    attr_accessor :oauth_token, :app_id, :secret, :app_access_token, :code, :session_key
    attr_accessor :oauth_test_data, :subscription_test_data
  end
  
  def self.setup_test_data(data)
    # make data accessible to all our tests
    self.oauth_test_data = data["oauth_test_data"]
    self.subscription_test_data = data["subscription_test_data"]
    self.oauth_token = data["oauth_token"]
    self.app_id = data["oauth_test_data"]["app_id"]
    self.app_access_token = data["oauth_test_data"]["app_access_token"]
    self.secret = data["oauth_test_data"]["secret"]
    self.code = data["oauth_test_data"]["code"]
    self.session_key = data["oauth_test_data"]["session_key"]
  end
  
  def self.setup_test_user
    print "Setting up test users..."
    test_user_api = Koala::Facebook::TestUsers.new(:app_id => self.app_id, :secret => self.secret)
    @live_testing_user, @live_testing_friend = test_user_api.create_network(2, true, "read_stream, publish_stream, user_photos, user_videos, read_insights")
    puts "done."
    @test_user = true
    self.oauth_token = @live_testing_user["access_token"]
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
  
  def self.real_user?
    !(mock_interface? || @test_user)
  end
  
  def self.test_user?
    !!@test_user
  end
  
  def self.mock_interface?
    Koala.http_service == Koala::MockHTTPService
  end
  
  def self.user1
    test_user? ? @live_testing_user["id"] : "koppel"
  end
  
  def self.user2
    test_user? ? @live_testing_user["id"] : "lukeshepard"
  end
  
  def self.page
    "contextoptional"
  end
  
end
