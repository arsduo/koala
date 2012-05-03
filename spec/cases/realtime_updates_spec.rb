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

  before :each do 
    @updates = Koala::Facebook::RealtimeUpdates.new(:app_id => @app_id, :secret => @secret)
  end

  describe ".new" do
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

  describe "#subscribe" do   
    it "makes a POST to the subscription path" do
      @updates.api.should_receive(:graph_call).with(@updates.subscription_path, anything, "post", anything)
      @updates.subscribe("user", "name", @subscription_path, @verify_token)
    end

    it "properly formats the subscription request" do
      obj = "user"
      fields = "name"
      @updates.api.should_receive(:graph_call).with(anything, hash_including(
        :object => obj,
        :fields => fields,
        :callback_url => @subscription_path,
        :verify_token => @verify_token 
      ), anything, anything)
      @updates.subscribe("user", "name", @subscription_path, @verify_token)
    end
    
    pending "doesn't require a verify_token" do
      # see https://github.com/arsduo/koala/issues/150
      obj = "user"
      fields = "name"
      @updates.api.should_not_receive(:graph_call).with(anything, hash_including(:verify_token => anything), anything, anything)
      @updates.subscribe("user", "name", @subscription_path)
    end
    
    it "requires verify_token" do
      expect { @updates.subscribe("user", "name", @subscription_path) }.to raise_exception
    end
    
    it "accepts an options hash" do
      options = {:a => 2, :b => "c"}
      @updates.api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options))
      @updates.subscribe("user", "name", @subscription_path, @verify_token, options)
    end

    describe "in practice" do
      it "sends a subscription request" do
        expect { @updates.subscribe("user", "name", @subscription_path, @verify_token) }.to_not raise_error
      end
    
      pending "sends a subscription request without a verify token" do
        expect { @updates.subscribe("user", "name", @subscription_path) }.to_not raise_error
      end
  
      it "fails if you try to hit an invalid path on your valid server" do
        expect { result = @updates.subscribe("user", "name", @subscription_path + "foo", @verify_token) }.to raise_exception(Koala::Facebook::APIError)
      end
  
      it "fails to send a subscription request to an invalid server" do
        expect { @updates.subscribe("user", "name", "foo", @verify_token) }.to raise_exception(Koala::Facebook::APIError)
      end
    end
  end
  
  describe "#unsubscribe" do
    it "makes a DELETE to the subscription path" do
      @updates.api.should_receive(:graph_call).with(@updates.subscription_path, anything, "delete", anything)
      @updates.unsubscribe("user")
    end

    it "includes the object if provided" do
      obj = "user"
      @updates.api.should_receive(:graph_call).with(anything, hash_including(:object => obj), anything, anything)
      @updates.unsubscribe(obj)
    end
        
    it "accepts an options hash" do
      options = {:a => 2, :b => "C"}
      @updates.api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options))
      @updates.unsubscribe("user", options)
    end
    
    describe "in practice" do
      it "unsubscribes a valid individual object successfully" do 
        expect { @updates.unsubscribe("user") }.to_not raise_error
      end

      it "unsubscribes all subscriptions successfully" do 
        expect { @updates.unsubscribe }.to_not raise_error
      end

      it "fails when an invalid object is provided to unsubscribe" do 
        expect { @updates.unsubscribe("kittens") }.to raise_error(Koala::Facebook::APIError)
      end
    end
  end
  
  describe "#list_subscriptions" do
    it "GETs the subscription path" do
      @updates.api.should_receive(:graph_call).with(@updates.subscription_path, anything, "get", anything)
      @updates.list_subscriptions
    end
    
    it "accepts options" do
      options = {:a => 3, :b => "D"}      
      @updates.api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options))
      @updates.list_subscriptions(options)
    end
    
    describe "in practice" do
      it "lists subscriptions properly" do
        @updates.list_subscriptions.should be_a(Array)
      end
    end
  end
  
  describe "#subscription_path" do
    it "returns the app_id/subscriptions" do
      @updates.subscription_path.should == "#{@app_id}/subscriptions"
    end
  end
  
  describe ".meet_challenge" do
    it "returns false if hub.mode isn't subscribe" do
      params = {'hub.mode' => 'not subscribe'}
      Koala::Facebook::RealtimeUpdates.meet_challenge(params).should be_false
    end

    it "doesn't evaluate the block if hub.mode isn't subscribe" do
      params = {'hub.mode' => 'not subscribe'}
      block_evaluated = false
      Koala::Facebook::RealtimeUpdates.meet_challenge(params){|token| block_evaluated = true}
      block_evaluated.should be_false
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
    end
  end
end
