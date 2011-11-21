require 'spec_helper'

describe "Koala::Facebook::RealtimeUpdates" do
  before :all do
    # get oauth data
    @app_id = KoalaTest.app_id
    @secret = KoalaTest.secret
    @callback_url = KoalaTest.oauth_test_data["callback_url"]
    @app_access_token = KoalaTest.app_access_token
    
    # check OAuth data
    unless @app_id && @secret && @callback_url && @app_access_token
      raise Exception, "Must supply OAuth app id, secret, app_access_token, and callback to run live subscription tests!" 
    end
    
    # get subscription data
    @verify_token = KoalaTest.subscription_test_data["verify_token"]
    @challenge_data = KoalaTest.subscription_test_data["challenge_data"]
    @subscription_path = KoalaTest.subscription_test_data["subscription_path"]
    
    # check subscription data
    unless @verify_token && @challenge_data && @subscription_path
      raise Exception, "Must supply verify_token and equivalent challenge_data to run subscription tests!" 
    end
  end

  describe "when initializing" do
    # basic initialization
    it "initializes properly with an app_id and an app_access_token" do
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
      updates.should be_a(Koala::Facebook::RealtimeUpdates)
    end
    
    # attributes
    it "allows read access to app_id" do
      # in Ruby 1.9, .method returns symbols 
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should include(:app_id)
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should_not include(:app_id=)
    end

    it "allows read access to app_access_token" do
      # in Ruby 1.9, .method returns symbols 
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should include(:app_access_token)
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should_not include(:app_access_token=)
    end

    it "allows read access to secret" do
      # in Ruby 1.9, .method returns symbols 
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should include(:secret)
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should_not include(:secret=)
    end

    it "allows read access to api" do
      # in Ruby 1.9, .method returns symbols 
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should include(:api)
      Koala::Facebook::RealtimeUpdates.instance_methods.map(&:to_sym).should_not include(:api=)
    end

    # old graph_api accessor
    it "returns the api object when graph_api is called" do
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      updates.graph_api.should == updates.api
    end

    it "fire a deprecation warning when graph_api is called" do
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      Koala::Utils.should_receive(:deprecate)
      updates.graph_api
    end
    
    # init with secret / fetching the token
    it "initializes properly with an app_id and a secret" do 
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      updates.should be_a(Koala::Facebook::RealtimeUpdates)      
    end

    it "fetches an app_token from Facebook when provided an app_id and a secret" do 
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
      updates.app_access_token.should_not be_nil
    end
        
    it "uses the OAuth class to fetch a token when provided an app_id and a secret" do
      oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
      token = oauth.get_app_access_token
      oauth.should_receive(:get_app_access_token).and_return(token)
      Koala::Facebook::OAuth.should_receive(:new).with(@app_id, @secret).and_return(oauth) 
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
    end
    
    it "sets up the with the app acces token" do 
      updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :app_access_token => @app_access_token)
      updates.api.should be_a(Koala::Facebook::API)
      updates.api.access_token.should == @app_access_token
    end    
    
  end

  describe "when used" do
    before :each do 
      @updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
    end
    
    it "sends a subscription request to a valid server" do
      result = @updates.subscribe("user", "name", @subscription_path, @verify_token)
      result.should be_true
    end
    
    it "sends a subscription request to a valid server" do
      result = @updates.subscribe("user", "name", @subscription_path, @verify_token)
      result.should be_true
    end
    
    it "sends a subscription request to an invalid path on a valid server" do
      lambda { result = @updates.subscribe("user", "name", @subscription_path + "foo", @verify_token) }.should raise_exception(Koala::Facebook::APIError)
    end
    
    it "fails to send a subscription request to an invalid server" do
      lambda { @updates.subscribe("user", "name", "foo", @verify_token) }.should raise_exception(Koala::Facebook::APIError)
    end
  
    it "unsubscribes a valid individual object successfully" do 
      @updates.unsubscribe("user").should be_true
    end

    it "unsubscribes all subscriptions successfully" do 
      @updates.unsubscribe.should be_true
    end

    it "fails when an invalid object is provided to unsubscribe" do 
      lambda { @updates.unsubscribe("kittens") }.should raise_error(Koala::Facebook::APIError)
    end
    
    it "lists subscriptions properly" do
      @updates.list_subscriptions.should be_a(Array)
    end
  end # describe "when used"
  
  describe "when meeting challenge" do
    it "returns false if hub.mode isn't subscribe" do
      params = {'hub.mode' => 'not subscribe'}
      Koala::Facebook::RealtimeUpdates.meet_challenge(params).should be_false
    end
    
    it "returns false if not given a verify_token or block" do
      params = {'hub.mode' => 'subscribe'}
      Koala::Facebook::RealtimeUpdates.meet_challenge(params).should be_false
    end
    
    describe "and mode is 'subscribe'" do
      before(:each) do 
        @params = {'hub.mode' => 'subscribe'}
      end
      
      describe "and a token is given" do
        before(:each) do
          @token = 'token'
          @params['hub.verify_token'] = @token
        end
        
        it "returns false if the given verify token doesn't match" do
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params, @token + '1').should be_false
        end
        
        it "returns the challenge if the given verify token matches" do
          @params['hub.challenge'] = 'challenge val'
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params, @token).should == @params['hub.challenge']
        end
      end
      
      describe "and a block is given" do
        before :each do
          @params['hub.verify_token'] = @token
        end
          
        it "gives the block the token as a parameter" do
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params) do |token|
            token.should == @token
          end
        end
        
        it "returns false if the given block return false" do
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params) do |token|
            false
          end.should be_false
        end
        
        it "returns false if the given block returns nil" do
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params) do |token|
            nil
          end.should be_false
        end
        
        it "returns the challenge if the given block returns true" do
          @params['hub.challenge'] = 'challenge val'
          Koala::Facebook::RealtimeUpdates.meet_challenge(@params) do |token|
            true
          end.should be_true
        end
      end
    
    end # describe "and mode is subscribe"
    
  end # describe "when meeting challenge"
  
end # describe
