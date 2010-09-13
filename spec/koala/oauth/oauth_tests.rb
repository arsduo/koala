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
  describe "Koala OAuth tests" do
    before :each do
      # make the relevant test data easily accessible
      @oauth_data = $testing_data["oauth_test_data"]
      @app_id = @oauth_data["app_id"]
      @secret = @oauth_data["secret"]
      @code = @oauth_data["code"]
      @callback_url = @oauth_data["callback_url"]
      @raw_token_string = @oauth_data["raw_token_string"]
      @raw_offline_access_token_string = @oauth_data["raw_offline_access_token_string"]
      
      # per Facebook's example:
      # http://developers.facebook.com/docs/authentication/canvas
      # this allows us to use Facebook's example data while running the other live data
      @request_secret = @oauth_data["request_secret"] || @secret 
      @signed_request = @oauth_data["signed_request"]
      @signed_request_result = @oauth_data["signed_request_result"]
      
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
    
    describe "for cookie parsing" do
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

        it "should use return a string if the cookies are valid" do
          result = @oauth.get_user_from_cookies(@oauth_data["valid_cookies"])
          result.should be_a(String)
        end
        
        it "should return nil if the cookies are invalid" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @oauth_data["valid_cookies"].inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_from_cookies(bad_cookie_hash)
          result.should be_nil
        end        
      end
    end
    
    # OAuth URLs
    
    describe "for URL generation" do

      describe "for OAuth codes" do 
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
      end
    
      describe "for access token URLs" do

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
      end
    end
  
    describe "for fetching access tokens" do 
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
      end
      
      describe "protected methods" do
      
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
      end
    end

    describe "for exchanging session keys" do
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
        
        it "should properly handle invalid session keys" do
          result = @oauth.get_token_info_from_session_keys(["foo", "bar"])
          #it should return nil for each of the invalid ones
          result.each {|r| r.should be_nil}
        end
        
        it "should properly handle a mix of valid and invalid session keys" do
          result = @oauth.get_token_info_from_session_keys(["foo"].concat(@oauth_data["multiple_session_keys"]))
          # it should return nil for each of the invalid ones
          result.each_with_index {|r, index| index > 0 ? r.should(be_a(Hash)) : r.should(be_nil)}
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
        
        it "should properly handle invalid session keys" do
          result = @oauth.get_tokens_from_session_keys(["foo", "bar"])
          # it should return nil for each of the invalid ones
          result.each {|r| r.should be_nil}
        end
        
        it "should properly handle a mix of valid and invalid session keys" do
          result = @oauth.get_tokens_from_session_keys(["foo"].concat(@oauth_data["multiple_session_keys"]))
          # it should return nil for each of the invalid ones
          result.each_with_index {|r, index| index > 0 ? r.should(be_a(String)) : r.should(be_nil)}
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
        
        it "should properly handle an invalid session key" do
          result = @oauth.get_token_from_session_key("foo")
          result.should be_nil
        end
      end    
    end
    
    describe "for parsing signed requests" do
      before :each do 
        # you can test against live data by updating the YML, or you can use the default data
        # which tests against Facebook's example on http://developers.facebook.com/docs/authentication/canvas
        @oauth = Koala::Facebook::OAuth.new(@app_id, @request_secret || @app_secret)
      end

      it "should break the request into the encoded signature and the payload" do
        @signed_request.should_receive(:split).with(".").and_return(["", ""])
        @oauth.parse_signed_request(@signed_request)
      end
      
      it "should base64 URL decode the signed request" do
        sig = ""
        @signed_request.should_receive(:split).with(".").and_return([sig, "1"])
        @oauth.should_receive(:base64_url_decode).with(sig).and_return("4")
        @oauth.parse_signed_request(@signed_request)
      end

      it "should base64 URL decode the signed request" do
        sig = @signed_request.split(".")[0]
        @oauth.should_receive(:base64_url_decode).with(sig).and_return(nil)
        @oauth.parse_signed_request(@signed_request)        
      end
      
      it "should get the sha64 encoded payload using proper arguments from OpenSSL::HMAC" do
        payload = ""
        @signed_request.should_receive(:split).with(".").and_return(["1", payload])
        OpenSSL::HMAC.should_receive(:digest).with("sha256", @request_secret, payload)
        @oauth.parse_signed_request(@signed_request)        
      end
      
      it "should compare the encoded payload with the signature" do
        sig = "2"
        @oauth.should_receive(:base64_url_decode).and_return(sig)
        encoded_payload = "1"
        OpenSSL::HMAC.should_receive(:digest).with(anything, anything, anything).and_return(encoded_payload)
        encoded_payload.should_receive(:==).with(sig)
        @oauth.parse_signed_request(@signed_request)                
      end
        
      describe "if the encoded payload matches the signature" do
        before :each do
          # set it up so the sig will match the encoded payload
          raw_sig = ""
          @sig = "2"
          @payload = "1"
          @signed_request.should_receive(:split).and_return([raw_sig, @payload])
          @oauth.should_receive(:base64_url_decode).with(raw_sig).and_return(@sig)
          OpenSSL::HMAC.should_receive(:digest).with(anything, anything, anything).and_return(@sig.dup)
        end
        
        it "should base64_url_decode the payload" do
          @oauth.should_receive(:base64_url_decode).with(@payload).ordered.and_return("{}")
          @oauth.parse_signed_request(@signed_request)        
        end
        
        it "should JSON decode the payload" do
          result = "{}"
          @oauth.should_receive(:base64_url_decode).with(@payload).and_return(result)
          JSON.should_receive(:parse).with(result)
          @oauth.parse_signed_request(@signed_request)        
        end
      end

      describe "if the encoded payload does not match the signature" do
        before :each do
          sig = ""
          @signed_request.should_receive(:split).and_return([sig, ""])
          OpenSSL::HMAC.should_receive(:digest).with(anything, anything, anything).and_return("hi")
        end
        
        it "should return nil" do
          @oauth.parse_signed_request(@signed_request).should be_nil
        end
      end
      
      describe "run against data" do
        it "should work" do
          @oauth.parse_signed_request(@signed_request).should == @signed_request_result
        end
      end
    end

  end # describe

end #class
