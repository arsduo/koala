require 'spec_helper'

describe "Koala::Facebook::OAuth" do
  before :each do
    # make the relevant test data easily accessible
    @app_id = KoalaTest.app_id
    @secret = KoalaTest.secret
    @code = KoalaTest.code
    @callback_url = KoalaTest.oauth_test_data["callback_url"]
    @access_token = KoalaTest.oauth_test_data["access_token"]
    @raw_token_string = KoalaTest.oauth_test_data["raw_token_string"]
    @raw_offline_access_token_string = KoalaTest.oauth_test_data["raw_offline_access_token_string"]

    # for signed requests (http://developers.facebook.com/docs/authentication/canvas/encryption_proposal)
    @signed_params = KoalaTest.oauth_test_data["signed_params"]
    @signed_params_result = KoalaTest.oauth_test_data["signed_params_result"]

    # this should expanded to cover all variables
    raise Exception, "Must supply app data to run FacebookOAuthTests!" unless @app_id && @secret && @callback_url &&
                                                                              @raw_token_string &&
                                                                              @raw_offline_access_token_string

    # we can just test against the same key twice
    @multiple_session_keys = [KoalaTest.session_key, KoalaTest.session_key] if KoalaTest.session_key

    @oauth = Koala::Facebook::OAuth.new(@app_id, @secret, @callback_url)

    @time = Time.now
    Time.stub!(:now).and_return(@time)
    @time.stub!(:to_i).and_return(1273363199)
  end

  describe ".new" do
    it "properly initializes" do
      @oauth.should
    end

    it "properly sets attributes" do
      (@oauth.app_id == @app_id &&
        @oauth.app_secret == @secret &&
        @oauth.oauth_callback_url == @callback_url).should be_true
    end

    it "properly initializes without a callback_url" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
    end

    it "properly sets attributes without a callback URL" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
      (@oauth.app_id == @app_id &&
        @oauth.app_secret == @secret &&
        @oauth.oauth_callback_url == nil).should be_true
    end
  end

  describe "for cookie parsing" do
    describe "get_user_info_from_cookies" do
      context "for signed cookies" do
        before :each do
          # we don't actually want to make requests to Facebook to redeem the code
          @cookie = KoalaTest.oauth_test_data["valid_signed_cookies"]
          @token = "my token"
          @oauth.stub(:get_access_token_info).and_return("access_token" => @token)
        end

        it "parses valid cookies" do
          result = @oauth.get_user_info_from_cookies(@cookie)
          result.should be_a(Hash)
        end

        it "returns all the components in the signed request" do
          result = @oauth.get_user_info_from_cookies(@cookie)
          @oauth.parse_signed_request(@cookie.values.first).each_pair do |k, v|
            result[k].should == v
          end
        end

        it "makes a request to Facebook to redeem the code if present" do
          code = "foo"
          @oauth.stub(:parse_signed_request).and_return({"code" => code})
          @oauth.should_receive(:get_access_token_info).with(code, anything)
          @oauth.get_user_info_from_cookies(@cookie)
        end

        it "sets the code redemption redirect_uri to ''" do
          @oauth.should_receive(:get_access_token_info).with(anything, :redirect_uri => '')
          @oauth.get_user_info_from_cookies(@cookie)
        end

        context "if the code is missing" do
          it "doesn't make a request to Facebook" do
            @oauth.stub(:parse_signed_request).and_return({})
            @oauth.should_receive(:get_access_token_info).never
            @oauth.get_user_info_from_cookies(@cookie)
          end

          it "returns nil" do
            @oauth.stub(:parse_signed_request).and_return({})
            @oauth.get_user_info_from_cookies(@cookie).should be_nil
          end

          it "logs a warning" do
            @oauth.stub(:parse_signed_request).and_return({})
            Koala::Utils.logger.should_receive(:warn)
            @oauth.get_user_info_from_cookies(@cookie)
          end
        end

        context "if the code is present" do
          it "adds the access_token into the hash" do
            @oauth.get_user_info_from_cookies(@cookie)["access_token"].should == @token
          end

          it "returns nil if the call to FB returns no data" do
            @oauth.stub(:get_access_token_info).and_return(nil)
            @oauth.get_user_info_from_cookies(@cookie).should be_nil
          end

          it "returns nil if the call to FB returns an expired code error" do
            @oauth.stub(:get_access_token_info).and_raise(Koala::Facebook::OAuthTokenRequestError.new(400, 
              '{ "error": { "type": "OAuthException", "message": "Code was invalid or expired. Session has expired at unix time 1324044000. The current unix time is 1324300957." } }'
            ))
            @oauth.get_user_info_from_cookies(@cookie).should be_nil
          end

          it "raises the error if the call to FB returns a different error" do
            @oauth.stub(:get_access_token_info).and_raise(Koala::Facebook::OAuthTokenRequestError.new(400,
              '{ "error": { "type": "OtherError", "message": "A Facebook Error" } }'))
            expect { @oauth.get_user_info_from_cookies(@cookie) }.to raise_exception(Koala::Facebook::OAuthTokenRequestError)
          end
        end

        it "doesn't parse invalid cookies" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @cookie.inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_info_from_cookies(bad_cookie_hash)
          result.should be_nil
        end
      end

      context "for unsigned cookies" do
        it "properly parses valid cookies" do
          result = @oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["valid_cookies"])
          result.should be_a(Hash)
        end

        it "returns all the cookie components from valid cookie string" do
          cookie_data = KoalaTest.oauth_test_data["valid_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          parsing_results.length.should == number_of_components
        end

        it "properly parses valid offline access cookies (e.g. no expiration)" do
          result = @oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["offline_access_cookies"])
          result["uid"].should
        end

        it "returns all the cookie components from offline access cookies" do
          cookie_data = KoalaTest.oauth_test_data["offline_access_cookies"]
          parsing_results = @oauth.get_user_info_from_cookies(cookie_data)
          number_of_components = cookie_data["fbs_#{@app_id.to_s}"].scan(/\=/).length
          parsing_results.length.should == number_of_components
        end

        it "doesn't parse expired cookies" do
          new_time = @time.to_i * 2
          @time.stub(:to_i).and_return(new_time)
          @oauth.get_user_info_from_cookies(KoalaTest.oauth_test_data["valid_cookies"]).should be_nil
        end

        it "doesn't parse invalid cookies" do
          # make an invalid string by replacing some values
          bad_cookie_hash = KoalaTest.oauth_test_data["valid_cookies"].inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_info_from_cookies(bad_cookie_hash)
          result.should be_nil
        end
      end
    end

    describe "get_user_from_cookies" do
      describe "for signed cookies" do
        before :each do
          # we don't actually want to make requests to Facebook to redeem the code
          @cookie = KoalaTest.oauth_test_data["valid_signed_cookies"]
          @oauth.stub(:get_access_token_info).and_return("access_token" => "my token")
        end

        it "does not uses get_user_info_from_cookies to parse the cookies" do
          @oauth.should_not_receive(:get_user_info_from_cookies).with(@cookie).and_return({})
          @oauth.get_user_from_cookies(@cookie)
        end

        it "uses return the facebook user id string if the cookies are valid" do
          result = @oauth.get_user_from_cookies(@cookie)
          result.should == "2905623" # the user who generated the original test cookie
        end

        it "returns nil if the cookies are invalid" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @cookie.inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_from_cookies(bad_cookie_hash)
          result.should be_nil
        end
      end

      describe "for unsigned cookies" do
        before :each do
          # we don't actually want to make requests to Facebook to redeem the code
          @cookie = KoalaTest.oauth_test_data["valid_cookies"]
        end

        it "uses get_user_info_from_cookies to parse the cookies" do
          @oauth.should_receive(:get_user_info_from_cookies).with(@cookie).and_return({})
          @oauth.get_user_from_cookies(@cookie)
        end

        it "uses return a string if the cookies are valid" do
          result = @oauth.get_user_from_cookies(@cookie)
          result.should == "2905623" # the user who generated the original test cookie
        end

        it "returns nil if the cookies are invalid" do
          # make an invalid string by replacing some values
          bad_cookie_hash = @cookie.inject({}) { |hash, value| hash[value[0]] = value[1].gsub(/[0-9]/, "3") }
          result = @oauth.get_user_from_cookies(bad_cookie_hash)
          result.should be_nil
        end
      end
    end
  end

  describe "for URL generation" do
    describe "#url_for_oauth_code" do
      it "generates a properly formatted OAuth code URL with the default values" do
        url = @oauth.url_for_oauth_code
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{CGI.escape @callback_url}")
      end

      it "generates a properly formatted OAuth code URL when a callback is given" do
        callback = "foo.com"
        url = @oauth.url_for_oauth_code(:callback => callback)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}")
      end

      it "generates a properly formatted OAuth code URL when permissions are requested as a string" do
        permissions = "publish_stream,read_stream"
        url = @oauth.url_for_oauth_code(:permissions => permissions)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&scope=#{CGI.escape permissions}&redirect_uri=#{CGI.escape @callback_url}")
      end

      it "generates a properly formatted OAuth code URL when permissions are requested as a string" do
        permissions = ["publish_stream", "read_stream"]
        url = @oauth.url_for_oauth_code(:permissions => permissions)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&scope=#{CGI.escape permissions.join(",")}&redirect_uri=#{CGI.escape @callback_url}")
      end

      it "generates a properly formatted OAuth code URL when both permissions and callback are provided" do
        permissions = "publish_stream,read_stream"
        callback = "foo.com"
        url = @oauth.url_for_oauth_code(:callback => callback, :permissions => permissions)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&scope=#{CGI.escape permissions}&redirect_uri=#{CGI.escape callback}")
      end

      it "generates a properly formatted OAuth code URL when a display is given as a string" do
        url = @oauth.url_for_oauth_code(:display => "page")
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&display=page&redirect_uri=#{CGI.escape @callback_url}")
      end

      it "raises an exception if no callback is given in initialization or the call" do
        oauth2 = Koala::Facebook::OAuth.new(@app_id, @secret)
        lambda { oauth2.url_for_oauth_code }.should raise_error(ArgumentError)
      end

      it "includes any additional options as URL parameters, appropriately escaped" do
        params = {
          :url => "http://foo.bar?c=2",
          :email => "cdc@b.com"
        }
        url = @oauth.url_for_oauth_code(params)
        params.each_pair do |key, value|
          url.should =~ /[\&\?]#{key}=#{CGI.escape value}/
        end
      end
    end

    describe "#url_for_access_token" do
      before :each do
        # since we're just composing a URL here, we don't need to have a real code
        @code ||= "test_code"
      end

      it "generates a properly formatted OAuth token URL when provided a code" do
        url = @oauth.url_for_access_token(@code)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&code=#{@code}&client_secret=#{@secret}&redirect_uri=#{CGI.escape @callback_url}").should be_true
      end

      it "generates a properly formatted OAuth token URL when provided a callback" do
        callback = "foo.com"
        url = @oauth.url_for_access_token(@code, :callback => callback)
        url.should match_url("https://#{Koala::Facebook::GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&code=#{@code}&client_secret=#{@secret}&redirect_uri=#{CGI.escape callback}").should be_true
      end

      it "includes any additional options as URL parameters, appropriately escaped" do
        params = {
          :url => "http://foo.bar?c=2",
          :email => "cdc@b.com"
        }
        url = @oauth.url_for_access_token(@code, params)
        params.each_pair do |key, value|
          url.should =~ /[\&\?]#{key}=#{CGI.escape value}/
        end
      end
    end

    describe "#url_for_dialog" do
      it "builds the base properly" do
        dialog_type = "my_dialog_type"
        @oauth.url_for_dialog(dialog_type).should =~ /^http:\/\/#{Koala::Facebook::DIALOG_HOST}\/dialog\/#{dialog_type}/
      end

      it "adds the app_id/client_id to the url" do
        automatic_params = {:app_id => @app_id, :client_id => @client_id}
        url = @oauth.url_for_dialog("foo", automatic_params)
        automatic_params.each_pair do |key, value|
          # we're slightly simplifying how encode_params works, but for strings/ints, it's okay
          url.should =~ /[\&\?]#{key}=#{CGI.escape value.to_s}/
        end
      end

      it "includes any additional options as URL parameters, appropriately escaped" do
        params = {
          :url => "http://foo.bar?c=2",
          :email => "cdc@b.com"
        }
        url = @oauth.url_for_dialog("friends", params)
        params.each_pair do |key, value|
          # we're slightly simplifying how encode_params works, but strings/ints, it's okay
          url.should =~ /[\&\?]#{key}=#{CGI.escape value.to_s}/
        end
      end

      describe "real examples from FB documentation" do
        # see http://developers.facebook.com/docs/reference/dialogs/
        # slightly brittle (e.g. if parameter order changes), but still useful
        it "can generate a send dialog" do
          url = @oauth.url_for_dialog("send", :name => "People Argue Just to Win", :link => "http://www.nytimes.com/2011/06/15/arts/people-argue-just-to-win-scholars-assert.html")
          url.should match_url("http://www.facebook.com/dialog/send?app_id=#{@app_id}&client_id=#{@app_id}&link=http%3A%2F%2Fwww.nytimes.com%2F2011%2F06%2F15%2Farts%2Fpeople-argue-just-to-win-scholars-assert.html&name=People+Argue+Just+to+Win&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "can generate a feed dialog" do
          url = @oauth.url_for_dialog("feed", :name => "People Argue Just to Win", :link => "http://www.nytimes.com/2011/06/15/arts/people-argue-just-to-win-scholars-assert.html")
          url.should match_url("http://www.facebook.com/dialog/feed?app_id=#{@app_id}&client_id=#{@app_id}&link=http%3A%2F%2Fwww.nytimes.com%2F2011%2F06%2F15%2Farts%2Fpeople-argue-just-to-win-scholars-assert.html&name=People+Argue+Just+to+Win&redirect_uri=#{CGI.escape @callback_url}")
        end

        it "can generate a oauth dialog" do
          url = @oauth.url_for_dialog("oauth", :scope => "email", :response_type => "token")
          url.should match_url("http://www.facebook.com/dialog/oauth?app_id=#{@app_id}&client_id=#{@app_id}&redirect_uri=#{CGI.escape @callback_url}&response_type=token&scope=email")
        end

        it "can generate a pay dialog" do
          url = @oauth.url_for_dialog("pay", :order_id => "foo", :credits_purchase => false)
          url.should match_url("http://www.facebook.com/dialog/pay?app_id=#{@app_id}&client_id=#{@app_id}&order_id=foo&credits_purchase=false&redirect_uri=#{CGI.escape @callback_url}")
        end
      end
    end
  end

  describe "for fetching access tokens" do
    describe "#get_access_token_info" do
      it "uses options[:redirect_uri] if provided" do
        uri = "foo"
        Koala.should_receive(:make_request).with(anything, hash_including(:redirect_uri => uri), anything, anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_access_token_info(@code, :redirect_uri => uri)
      end

      it "uses the redirect_uri used to create the @oauth if no :redirect_uri option is provided" do
        Koala.should_receive(:make_request).with(anything, hash_including(:redirect_uri => @callback_url), anything, anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_access_token_info(@code)
      end

      it "makes a GET request" do
        Koala.should_receive(:make_request).with(anything, anything, "get", anything).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_access_token_info(@code)
      end

      if KoalaTest.code
        it "properly gets and parses an access token token results into a hash" do
          result = @oauth.get_access_token_info(@code)
          result.should be_a(Hash)
        end

        it "properly includes the access token results" do
          result = @oauth.get_access_token_info(@code)
          result["access_token"].should
        end

        it "raises an error when get_access_token is called with a bad code" do
          lambda { @oauth.get_access_token_info("foo") }.should raise_error(Koala::Facebook::OAuthTokenRequestError)
        end
      end
    end

    describe "#get_access_token" do
      # TODO refactor these to be proper tests with stubs and tests against real data
      it "passes on any options provided to make_request" do
        options = {:a => 2}
        Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_access_token(@code, options)
      end

      if KoalaTest.code
        it "uses get_access_token_info to get and parse an access token token results" do
          result = @oauth.get_access_token(@code)
          result.should be_a(String)
        end

        it "returns the access token as a string" do
          result = @oauth.get_access_token(@code)
          original = @oauth.get_access_token_info(@code)
          result.should == original["access_token"]
        end

        it "raises an error when get_access_token is called with a bad code" do
          lambda { @oauth.get_access_token("foo") }.should raise_error(Koala::Facebook::OAuthTokenRequestError)
        end
      end
    end

    unless KoalaTest.code
      it "Some OAuth code tests will not be run since the code field in facebook_data.yml is blank."
    end

    describe "get_app_access_token_info" do
      it "properly gets and parses an app's access token as a hash" do
        result = @oauth.get_app_access_token_info
        result.should be_a(Hash)
      end

      it "includes the access token" do
        result = @oauth.get_app_access_token_info
        result["access_token"].should
      end

      it "passes on any options provided to make_request" do
        options = {:a => 2}
        Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_app_access_token_info(options)
      end
    end

    describe "get_app_access_token" do
      it "uses get_access_token_info to get and parse an access token token results" do
        result = @oauth.get_app_access_token
        result.should be_a(String)
      end

      it "returns the access token as a string" do
        result = @oauth.get_app_access_token
        original = @oauth.get_app_access_token_info
        result.should == original["access_token"]
      end

      it "passes on any options provided to make_request" do
        options = {:a => 2}
        Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.get_app_access_token(options)
      end
    end

    describe "exchange_access_token_info" do
      if KoalaTest.mock_interface? || KoalaTest.oauth_token
        it "properly gets and parses an app's access token as a hash" do
          result = @oauth.exchange_access_token_info(KoalaTest.oauth_token)
          result.should be_a(Hash)
        end

        it "includes the access token" do
          result = @oauth.exchange_access_token_info(KoalaTest.oauth_token)
          result["access_token"].should
        end
      else
        pending "Some OAuth token exchange tests will not be run since the access token field in facebook_data.yml is blank."
      end

      it "passes on any options provided to make_request" do
        options = {:a => 2}
        Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.exchange_access_token_info(KoalaTest.oauth_token, options)
      end

      it "raises an error when exchange_access_token_info is called with a bad code" do
        lambda { @oauth.exchange_access_token_info("foo") }.should raise_error(Koala::Facebook::OAuthTokenRequestError)
      end
    end

    describe "exchange_access_token" do
      it "uses get_access_token_info to get and parse an access token token results" do
        hash = {"access_token" => Time.now.to_i * rand}
        @oauth.stub(:exchange_access_token_info).and_return(hash)
        @oauth.exchange_access_token(KoalaTest.oauth_token).should == hash["access_token"]
      end

      it "passes on any options provided to make_request" do
        options = {:a => 2}
        Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "", {}))
        @oauth.exchange_access_token(KoalaTest.oauth_token, options)
      end
    end

    describe "protected methods" do
      # protected methods
      # since these are pretty fundamental and pretty testable, we want to test them

      # parse_access_token
      it "properly parses access token results" do
        result = @oauth.send(:parse_access_token, @raw_token_string)
        has_both_parts = result["access_token"] && result["expires"]
        has_both_parts.should
      end

      it "properly parses offline access token results" do
        result = @oauth.send(:parse_access_token, @raw_offline_access_token_string)
        has_both_parts = result["access_token"] && !result["expires"]
        has_both_parts.should
      end

      # fetch_token_string
      # somewhat duplicative with the tests for get_access_token and get_app_access_token
      # but no harm in thoroughness
      if KoalaTest.code
        it "fetches a proper token string from Facebook when given a code" do
          result = @oauth.send(:fetch_token_string, :code => @code, :redirect_uri => @callback_url)
          result.should =~ /^access_token/
        end
      else
        it "fetch_token_string code test will not be run since the code field in facebook_data.yml is blank."
      end

      it "fetches a proper token string from Facebook when asked for the app token" do
        result = @oauth.send(:fetch_token_string, {:type => 'client_cred'}, true)
        result.should =~ /^access_token/
      end
    end
  end

  describe "for exchanging session keys" do
    if KoalaTest.session_key
      describe "with get_token_info_from_session_keys" do
        it "gets an array of session keys from Facebook when passed a single key" do
          result = @oauth.get_tokens_from_session_keys([KoalaTest.session_key])
          result.should be_an(Array)
          result.length.should == 1
        end

        it "gets an array of session keys from Facebook when passed multiple keys" do
          result = @oauth.get_tokens_from_session_keys(@multiple_session_keys)
          result.should be_an(Array)
          result.length.should == 2
        end

        it "returns the original hashes" do
          result = @oauth.get_token_info_from_session_keys(@multiple_session_keys)
          result[0].should be_a(Hash)
        end

        it "properly handles invalid session keys" do
          result = @oauth.get_token_info_from_session_keys(["foo", "bar"])
          #it should return nil for each of the invalid ones
          result.each {|r| r.should be_nil}
        end

        it "properly handles a mix of valid and invalid session keys" do
          result = @oauth.get_token_info_from_session_keys(["foo"].concat(@multiple_session_keys))
          # it should return nil for each of the invalid ones
          result.each_with_index {|r, index| index > 0 ? r.should(be_a(Hash)) : r.should(be_nil)}
        end

        it "throws a BadFacebookResponse if Facebook returns an empty body (as happens for instance when the API breaks)" do
          @oauth.should_receive(:fetch_token_string).and_return("")
          lambda { @oauth.get_token_info_from_session_keys(@multiple_session_keys) }.should raise_error(Koala::Facebook::BadFacebookResponse)
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "[{}]", {}))
          @oauth.get_token_info_from_session_keys([], options)
        end
      end

      describe "with get_tokens_from_session_keys" do
        it "calls get_token_info_from_session_keys" do
          args = @multiple_session_keys
          @oauth.should_receive(:get_token_info_from_session_keys).with(args, anything).and_return([])
          @oauth.get_tokens_from_session_keys(args)
        end

        it "returns an array of strings" do
          args = @multiple_session_keys
          result = @oauth.get_tokens_from_session_keys(args)
          result.each {|r| r.should be_a(String) }
        end

        it "properly handles invalid session keys" do
          result = @oauth.get_tokens_from_session_keys(["foo", "bar"])
          # it should return nil for each of the invalid ones
          result.each {|r| r.should be_nil}
        end

        it "properly handles a mix of valid and invalid session keys" do
          result = @oauth.get_tokens_from_session_keys(["foo"].concat(@multiple_session_keys))
          # it should return nil for each of the invalid ones
          result.each_with_index {|r, index| index > 0 ? r.should(be_a(String)) : r.should(be_nil)}
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "[{}]", {}))
          @oauth.get_tokens_from_session_keys([], options)
        end
      end

      describe "get_token_from_session_key" do
        it "calls get_tokens_from_session_keys when the get_token_from_session_key is called" do
          key = KoalaTest.session_key
          @oauth.should_receive(:get_tokens_from_session_keys).with([key], anything).and_return([])
          @oauth.get_token_from_session_key(key)
        end

        it "gets back the access token string from get_token_from_session_key" do
          result = @oauth.get_token_from_session_key(KoalaTest.session_key)
          result.should be_a(String)
        end

        it "returns the first value in the array" do
          result = @oauth.get_token_from_session_key(KoalaTest.session_key)
          array = @oauth.get_tokens_from_session_keys([KoalaTest.session_key])
          result.should == array[0]
        end

        it "properly handles an invalid session key" do
          result = @oauth.get_token_from_session_key("foo")
          result.should be_nil
        end

        it "passes on any options provided to make_request" do
          options = {:a => 2}
          Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(options)).and_return(Koala::HTTPService::Response.new(200, "[{}]", {}))
          @oauth.get_token_from_session_key("", options)
        end
      end
    else
      it "Session key exchange tests will not be run since the session key in facebook_data.yml is blank."
    end
  end

  describe "for parsing signed requests" do
    # the signed request code is ported directly from Facebook
    # so we only need to test at a high level that it works
    it "throws an error if the algorithm is unsupported" do
      MultiJson.stub(:load).and_return("algorithm" => "my fun algorithm")
      lambda { @oauth.parse_signed_request(@signed_request) }.should raise_error
    end

    it "throws an error if the signature is invalid" do
      OpenSSL::HMAC.stub!(:hexdigest).and_return("i'm an invalid signature")
      lambda { @oauth.parse_signed_request(@signed_request) }.should raise_error
    end

    it "throws an error if the signature string is empty" do
      # this occasionally happens due to Facebook error
      lambda { @oauth.parse_signed_request("") }.should raise_error
      lambda { @oauth.parse_signed_request("abc-def") }.should raise_error
    end

    it "properly parses requests" do
      @oauth = Koala::Facebook::OAuth.new(@app_id, @secret || @app_secret)
      @oauth.parse_signed_request(@signed_params).should == @signed_params_result
    end
  end

end # describe
