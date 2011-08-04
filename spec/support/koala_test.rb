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
  
  def self.setup_test_users
    # note: we don't have to delete the two test users explicitly, since the test user specs do that for us
    # technically, this is a point of brittleness and would break if the tests were run out of order
    # however, for now we can live with it since it would slow tests way too much to constantly recreate our test users        
    print "Setting up test users..."
    @test_user_api = Koala::Facebook::TestUsers.new(:app_id => self.app_id, :secret => self.secret)
    perms = "read_stream, publish_stream, user_photos, user_videos, read_insights"

    # create two test users with specific names and befriend them
    @live_testing_user = @test_user_api.create(true, perms, :name => user1_name)
    @live_testing_friend = @test_user_api.create(true, perms, :name => user2_name)
    @test_user_api.befriend(@live_testing_user, @live_testing_friend)
    self.oauth_token = @live_testing_user["access_token"]
    
    puts "done."
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
    !!@test_user_api
  end
  
  def self.mock_interface?
    Koala.http_service == Koala::MockHTTPService
  end
  
  def self.user1
    test_user? ? @live_testing_user["id"] : "koppel"
  end
  
  def self.user1_id
    test_user? ? @live_testing_user["id"] : 2905623
  end

  def self.user1_name
    "Alex"
  end
  
  def self.user2
    test_user? ? @live_testing_friend["id"] : "lukeshepard"
  end

  def self.user2_id
    test_user? ? @live_testing_friend["id"] : 2901279
  end
  
  def self.user2_name
    "Luke"
  end
  
  def self.page
    "contextoptional"
  end
  
end
