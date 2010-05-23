class FacebookRealtimeUpdatesTests < Test::Unit::TestCase
  include Koala
  
  describe "Koala RealtimeUpdates" do
    before :all do
      # get oauth data
      @oauth_data = $testing_data["oauth_test_data"]
      @app_id = @oauth_data["app_id"]
      @secret = @oauth_data["secret"]
      @callback_url = @oauth_data["callback_url"]
      @app_access_token = @oauth_data["app_access_token"]
      
      # check OAuth data
      unless @app_id && @secret && @callback_url && @app_access_token
        raise Exception, "Must supply OAuth app id, secret, app_access_token, and callback to run live subscription tests!" 
      end
      
      # get subscription data
      @subscription_data = $testing_data["subscription_test_data"]
      @verify_token = @subscription_data["verify_token"]
      @challenge_data = @subscription_data["challenge_data"]
      @subscription_path = @subscription_data["subscription_path"]
      
      # check subscription data
      unless @verify_token && @challenge_data && @subscription_path
        raise Exception, "Must supply verify_token and equivalent challenge_data to run live subscription tests!" 
      end
    end

    describe "when initializing" do
      # basic initialization
      it "should initialize properly with an app_id and an app_access_token" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        updates.should be_a(Facebook::RealtimeUpdates)
      end
      
      # attributes
      it "should allow read access to app_id, app_access_token, and secret" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        updates.app_id && updates.app_access_token && updates.secret
      end
      
      it "should not allow write access to app_id" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        lambda { updates.app_id = 2 }.should raise_error(NoMethodError)
      end

      it "should not allow write access to app_access_token" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        lambda { updates.app_access_token = 2 }.should raise_error(NoMethodError)
      end
    
      it "should not allow write access to secret" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        lambda { updates.secret = 2 }.should raise_error(NoMethodError)
      end
      
      # init with secret / fetching the token
      it "should initialize properly with an app_id and a secret" do 
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
        updates.should be_a(Facebook::RealtimeUpdates)      
      end

      it "should fetch an app_token from Facebook when provided an app_id and a secret" do 
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
        updates.app_access_token.should_not be_nil
      end
      
      it "should use the OAuth class to fetch a token when provided an app_id and a secret" do
        oauth = Facebook::OAuth.new(@app_id, @secret)
        token = oauth.get_app_access_token
        oauth.should_receive(:get_app_access_token).and_return(token)
        Facebook::OAuth.should_receive(:new).with(@app_id, @secret).and_return(oauth) 
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      end
    end
  
    describe "when used" do
      before :each do 
        @updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      end
      
      it "should send a subscription request to a valid server" do
        result = @updates.subscribe("user", "name", @subscription_path, @verify_token)
        result.should be_true
      end
      
      it "should send a subscription request to a valid server" do
        result = @updates.subscribe("user", "name", @subscription_path, @verify_token)
        result.should be_true
      end
      
      it "should send a subscription request to an invalid path on a valid server" do
        lambda { result = @updates.subscribe("user", "name", @subscription_path + "foo", @verify_token) }.should raise_exception(Koala::Facebook::APIError)
      end
      
      it "should fail to send a subscription request to an invalid server" do
        lambda { @updates.subscribe("user", "name", "foo", @verify_token) }.should raise_exception(Koala::Facebook::APIError)
      end
    
      it "should unsubscribe a valid individual object successfully" do 
        @updates.unsubscribe("user").should be_true
      end

      it "should unsubscribe all subscriptions successfully" do 
        @updates.unsubscribe.should be_true
      end

      it "should fail when an invalid object is provided to unsubscribe" do 
        lambda { @updates.unsubscribe("kittens") }.should raise_error(Koala::Facebook::APIError)
      end
      
      it "should is subscriptions properly" do
        @updates.list_subscriptions["data"].should be_a(Array)
      end
 
    end # describe "when used"
    
  end # describe

end #class
