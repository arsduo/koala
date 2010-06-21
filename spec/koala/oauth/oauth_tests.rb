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
    
    describe "cookie parsing" do
      describe "get_user_info_from_cookies" do
        it "should properly parse valid cookies" do
          result = @oauth.get_user_info_from_cookies(@oauth_data["valid_cookies"])
          result.should be_a(Hash)
        end
    
        it "should return all the cookie components from valid cookie string" do
          cookie_data = @oauth_data["valid_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          parsing_results.length.should == number_of_components
        end

        it "should properly parse valid offline access cookies (e.g. no expiration)" do 
          result = @oauth.get_user_info_from_cookies(@oauth_data["offline_access_cookies"])
          result["uid"].should      
        end

        it "should return all the cookie components from offline access cookies" do
          cookie_data = @oauth_data["offline_access_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          parsing_results.length.should == number_of_components
        end

        it "shouldn't parse expired cookies" do
          result = @oauth.get_user_info_from_cookies(@oauth_data["expired_cookies"])
          result.should be_nil
        end
    
        it "shouldn't parse invalid cookies" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @oauth_data["valid_cookies"].inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_info_from_cookies(bad_cookie_hash)
          result.should be_nil
        end
      end
      
      describe "get_user_from_cookies" do
        it "should use get_user_info_from_cookies to parse the cookies" do
          data = @oauth_data["valid_cookies"]
          @oauth.should_receive(:get_user_info_from_cookies).with(data).and_return({})
          @oauth.get_user_from_cookies(data)
        end

        it "should use return a string" do
          result = @oauth.get_user_from_cookies(@oauth_data["valid_cookies"])
          result.should be_a(String)
        end
        
        describe "backward compatibility" do
          before :each do
            @result = @oauth.get_user_from_cookies(@oauth_data["valid_cookies"])
            @key = "uid"
          end
          
          it_should_behave_like "methods that return overloaded strings"
        end
      end
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

    describe "get_access_token_info" do
      it "should properly get and parse an access token token results into a hash" do
        result = @oauth.get_access_token_info(@code)
        result.should be_a(Hash)
      end

      it "should properly include the access token results" do
        result = @oauth.get_access_token_info(@code)
        result["access_token"].should
      end

      it "should raise an error when get_access_token is called with a bad code" do
        lambda { @oauth.get_access_token_info("foo") }.should raise_error(Koala::Facebook::APIError) 
      end
    end

    describe "get_access_token" do
      it "should use get_access_token_info to get and parse an access token token results" do
        result = @oauth.get_access_token(@code)
        result.should be_a(String)
      end

      it "should return the access token as a string" do
        result = @oauth.get_access_token(@code)
        original = @oauth.get_access_token_info(@code)
        result.should == original["access_token"]
      end

      it "should raise an error when get_access_token is called with a bad code" do
        lambda { @oauth.get_access_token("foo") }.should raise_error(Koala::Facebook::APIError) 
      end

      describe "backwards compatibility" do
        before :each do
          @result = @oauth.get_access_token(@code)
        end

        it_should_behave_like "methods that return overloaded strings"
      end
    end

    describe "get_app_access_token_info" do
      it "should properly get and parse an app's access token as a hash" do
        result = @oauth.get_app_access_token_info
        result.should be_a(Hash)
      end
    
      it "should include the access token" do
        result = @oauth.get_app_access_token_info
        result["access_token"].should
      end
    end
    
    describe "get_app_acess_token" do
      it "should use get_access_token_info to get and parse an access token token results" do
        result = @oauth.get_app_access_token
        result.should be_a(String)
      end

      it "should return the access token as a string" do
        result = @oauth.get_app_access_token
        original = @oauth.get_app_access_token_info
        result.should == original["access_token"]
      end
      
      describe "backwards compatibility" do
        before :each do
          @result = @oauth.get_app_access_token    
        end
        
        it_should_behave_like "methods that return overloaded strings"
      end
    end

    describe "exchanging session keys" do
      describe "with get_token_info_from_session_keys" do
        it "should get an array of session keys from Facebook when passed a single key" do
          result = @oauth.get_tokens_from_session_keys([@oauth_data["session_key"]])
          result.should be_an(Array)
          result.length.should == 1
        end

        it "should get an array of session keys from Facebook when passed multiple keys" do
          result = @oauth.get_tokens_from_session_keys(@oauth_data["multiple_session_keys"])
          result.should be_an(Array)
          result.length.should == 2
        end
        
        it "should return the original hashes" do
          result = @oauth.get_token_info_from_session_keys(@oauth_data["multiple_session_keys"])
          result[0].should be_a(Hash)
        end
      end
      
      describe "with get_tokens_from_session_keys" do
        it "should call get_token_info_from_session_keys" do
          args = @oauth_data["multiple_session_keys"]
          @oauth.should_receive(:get_token_info_from_session_keys).with(args).and_return([])
          @oauth.get_tokens_from_session_keys(args)
        end
        
        it "should return an array of strings" do
          args = @oauth_data["multiple_session_keys"]
          result = @oauth.get_tokens_from_session_keys(args)
          result.each {|r| r.should be_a(String) }
        end
        
        describe "backwards compatibility" do
          before :each do
            args = @oauth_data["multiple_session_keys"]
            @result = @oauth.get_tokens_from_session_keys(args)[0]
          end

          it_should_behave_like "methods that return overloaded strings"
        end
      end

      describe "get_token_from_session_key" do
        it "should call get_tokens_from_session_keys when the get_token_from_session_key is called" do
          key = @oauth_data["session_key"]
          @oauth.should_receive(:get_tokens_from_session_keys).with([key]).and_return([])
          @oauth.get_token_from_session_key(key)
        end

        it "should get back the access token string from get_token_from_session_key" do
          result = @oauth.get_token_from_session_key(@oauth_data["session_key"])
          result.should be_a(String)
        end

        it "should be the first value in the array" do
          result = @oauth.get_token_from_session_key(@oauth_data["session_key"])
          array = @oauth.get_tokens_from_session_keys([@oauth_data["session_key"]])
          result.should == array[0]
        end
        
        describe "backwards compatibility" do
          before :each do
            @result = @oauth.get_token_from_session_key(@oauth_data["session_key"])       
          end

          it_should_behave_like "methods that return overloaded strings"
        end
      end    
    end
    
    # protected methods
    # since these are pretty fundamental and pretty testable, we want to test them
    
    # parse_access_token
    it "should properly parse access token results" do
      result = @oauth.send(:parse_access_token, @raw_token_string)
      has_both_parts = result["access_token"] && result["expires"]
      has_both_parts.should
    end
    
    it "should properly parse offline access token results" do
      result = @oauth.send(:parse_access_token, @raw_offline_access_token_string)
      has_both_parts = result["access_token"] && !result["expires"]
      has_both_parts.should
    end
    
    # fetch_token_string
    # somewhat duplicative with the tests for get_access_token and get_app_access_token
    # but no harm in thoroughness
    it "should fetch a proper token string from Facebook when given a code" do
      result = @oauth.send(:fetch_token_string, :code => @code, :redirect_uri => @callback_url)
      result.should =~ /^access_token/
    end

    it "should fetch a proper token string from Facebook when asked for the app token" do
      result = @oauth.send(:fetch_token_string, {:type => 'client_cred'}, true)
      result.should =~ /^access_token/
    end
    
    # END CODE THAT NEEDS MOCKING
  end # describe

end #class
