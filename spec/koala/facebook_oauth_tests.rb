# stub the Time class to always return a time for which the valid cookie is still valid
class Time
  def self.now
    self
  end
  
  def self.to_i
    1273363199
  end
end

class FacebookOAuthTests < Test::Unit::TestCase
  describe "Koala GraphAPI without an access token" do
    before :each do
      # make the relevant test data easily accessible
      @oauth_data = $testing_data["oauth_test_data"]
      @app_id = @oauth_data["app_id"]
      @secret = @oauth_data["secret"]
      @code = @oauth_data["code"]
      @callback_url = @oauth_data["callback_url"]
      @raw_token_string = @oauth_data["raw_token_string"]
      @raw_offline_access_token_string = @oauth_data["raw_offline_access_token_string"]
      
      # this should expanded to cover all variables
      raise Exception, "Must supply app data to run FacebookOAuthTests!" unless @app_id && @secret && @callback_url && 
                                                                                @code && @raw_token_string && 
                                                                                @raw_offline_access_token_string

      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret, @callback_url)
    end
    
    # initialization
    it "should properly initialize" do
      @oauth.should
    end

    it "should properly set attributes" do
      (@oauth.app_id == @app_id && 
        @oauth.app_secret == @secret && 
        @oauth.oauth_callback_url == @callback_url).should be_true
    end

    it "should properly initialize without a callback_url" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
    end

    it "should properly set attributes without a callback URL" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
      (@oauth.app_id == @app_id && 
        @oauth.app_secret == @secret && 
        @oauth.oauth_callback_url == nil).should be_true
    end
    
    # cookie parsing
    it "should properly parse valid cookies" do
      result = @oauth.get_user_from_cookie(@oauth_data["valid_cookies"])
      result["uid"].should
    end
    
    it "should return all the cookie components from valid cookie string" do
      cookie_data = @oauth_data["valid_cookies"]
      parsing_results = @oauth.get_user_from_cookie(cookie_data)
      number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
      parsing_results.length.should == number_of_components
    end

    it "should properly parse valid offline access cookies (e.g. no expiration)" do 
      result = @oauth.get_user_from_cookie(@oauth_data["offline_access_cookies"])
      result["uid"].should      
    end

    it "should return all the cookie components from offline access cookies" do
      cookie_data = @oauth_data["offline_access_cookies"]
      parsing_results = @oauth.get_user_from_cookie(cookie_data)
      number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
      parsing_results.length.should == number_of_components
    end

    it "shouldn't parse expired cookies" do
      result = @oauth.get_user_from_cookie(@oauth_data["expired_cookies"])
      result.should be_nil
    end
    
    it "shouldn't parse invalid cookies" do
      # make an invalid string by replacing some values
      bad_cookie_hash = @oauth_data["valid_cookies"].inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
      result = @oauth.get_user_from_cookie(bad_cookie_hash)
      result.should be_nil
    end
    
    # OAuth URLs
    
    # url_for_oauth_code
    it "should generate a properly formatted OAuth code URL with the default values" do 
      url = @oauth.url_for_oauth_code
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{@callback_url}"
    end

    it "should generate a properly formatted OAuth code URL when a callback is given" do 
      callback = "foo.com"
      url = @oauth.url_for_oauth_code(:callback => callback)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}"
    end

    it "should generate a properly formatted OAuth code URL when permissions are requested as a string" do 
      permissions = "publish_stream,read_stream"
      url = @oauth.url_for_oauth_code(:permissions => permissions)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{@callback_url}&scope=#{permissions}"
    end

    it "should generate a properly formatted OAuth code URL when permissions are requested as a string" do 
      permissions = ["publish_stream", "read_stream"]
      url = @oauth.url_for_oauth_code(:permissions => permissions)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{@callback_url}&scope=#{permissions.join(",")}"
    end

    it "should generate a properly formatted OAuth code URL when both permissions and callback are provided" do 
      permissions = "publish_stream,read_stream"
      callback = "foo.com"
      url = @oauth.url_for_oauth_code(:callback => callback, :permissions => permissions)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}&scope=#{permissions}"
    end

    it "should raise an exception if no callback is given in initialization or the call" do 
      oauth2 = Koala::Facebook::OAuth.new(@app_id, @secret)
      lambda { oauth2.url_for_oauth_code }.should raise_error(ArgumentError)
    end

    # url_for_access_token
    it "should generate a properly formatted OAuth token URL when provided a code" do 
      url = @oauth.url_for_access_token(@code)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{@callback_url}&client_secret=#{@secret}&code=#{@code}"
    end

    it "should generate a properly formatted OAuth token URL when provided a callback" do 
      callback = "foo.com"
      url = @oauth.url_for_access_token(@code, :callback => callback)
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{callback}&client_secret=#{@secret}&code=#{@code}"
    end
    
    it "should output a deprecation warning but generate a properly formatted OAuth token URL when provided a callback in the deprecated fashion" do 
      callback = "foo.com"
      url = out = nil
      
      begin
        # we want to capture the deprecation warning as well as the output
        # credit to http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/ for the technique
        out = StringIO.new
        $stdout = out
        url = @oauth.url_for_access_token(@code, callback)
      ensure
        $stdout = STDOUT
      end
      
      # two assertions may be bad test writing, but this is for a deprecated method
      url.should == "https://#{Koala::Facebook::GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{callback}&client_secret=#{@secret}&code=#{@code}"
      out.should_not be_nil
    end

    # START CODE THAT NEEDS MOCKING

    # get_access_token
    it "should properly get and parse an access token token results" do
      result = @oauth.get_access_token(@code)
      result["access_token"].should
    end

    it "should raise an error when get_access_token is called with a bad code" do
      lambda { @oauth.get_access_token("foo") }.should raise_error(Koala::Facebook::APIError) 
    end
    
    it "should properly get and parse an app's access token token results" do
      result = @oauth.get_app_access_token
      result["access_token"].should
    end
    
    # protected methods
    # since these are pretty fundamental and pretty testable, we want to test them
    
    # parse_access_token
    it "should properly parse access token results" do
      result = @oauth.parse_access_token(@raw_token_string)
      has_both_parts = result["access_token"] && result["expires"]
      has_both_parts.should
    end
    
    it "should properly parse offline access token results" do
      result = @oauth.parse_access_token(@raw_offline_access_token_string)
      has_both_parts = result["access_token"] && !result["expires"]
      has_both_parts.should
    end
    
    # fetch_token_string
    # somewhat duplicative with the tests for get_access_token and get_app_access_token
    # but no harm in thoroughness
    it "should fetch a proper token string from Facebook when given a code" do
      result = @oauth.fetch_token_string(:code => @code)
      result.should =~ /^access_token/
    end

    it "should fetch a proper token string from Facebook when asked for the app token" do
      result = @oauth.fetch_token_string(:type => 'client_cred'}, true)
      result.should =~ /^access_token/
    end
    
    # END CODE THAT NEEDS MOCKING
  end # describe

end #class
