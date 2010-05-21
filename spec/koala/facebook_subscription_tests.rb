class FacebookSubscriptionTests < Test::Unit::TestCase
  include Koala
  
  describe "Koala RealtimeUpdates" do
    before :all do
      # get oauth data
      @oauth_data = $testing_data["oauth_test_data"]
      @app_id = @oauth_data["app_id"]
      @secret = @oauth_data["secret"]
      @callback_url = @oauth_data["callback_url"]
      @app_token = @oauth_data["app_token"]
      
      # check OAuth data
      unless @app_id && @secret && @callback_url && @app_token
        raise Exception, "Must supply OAuth app id, secret, app_token, and callback to run live subscription tests!" 
      end
      
      # get subscription data
      @subscription_data = $testing_data["subscription_test_data"]
      @verify_token = @subscription_data["verify_token"]
      @challenge_data = @subscription_data["challenge_data"]
      
      # check subscription data
      unless @verify_token && @challenge_data
        raise Exception, "Must supply verify_token and equivalent challenge_data to run live subscription tests!" 
      end
    end

    describe "when initializing" do
      it "should initialize properly with an app_id and an app_access_token" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        updates.should be_a(Facebook::RealtimeUpdates)
      end

      it "should allow read access to app_id, app_access_token, and secret" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        updates.app_id && updates.app_access_token && updates.secret
      end
      
      it "should not allow write access to app_id, app_access_token, or secret" do
        updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
        # this should not throw errors
        lambda { updates.app_id = 2 }.should raise_error 
      end

    
    end
    
    describe "when used" do
      before :each do 
        @updates = Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
      end
    end

  end # describe

end #class
