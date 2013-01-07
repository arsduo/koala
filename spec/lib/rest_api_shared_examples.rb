shared_examples_for "Koala RestAPI" do
  # REST_CALL
  describe "when making a rest request" do
    it "uses the proper path" do
      method = stub('methodName')
      @api.should_receive(:api).with(
        "method/#{method}",
        anything,
        anything,
        anything
      )

      @api.rest_call(method)
    end

    it "always uses the rest api" do
      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:rest_api => true)
      )

      @api.rest_call('anything')
    end

    it "sets the read_only option to true if the method is listed in the read-only list" do
      method = Koala::Facebook::RestAPI::READ_ONLY_METHODS.first

      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:read_only => true)
      )

      @api.rest_call(method)
    end

    it "sets the read_only option to false if the method is not inthe read-only list" do
      method = "I'm not a read-only method"

      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        hash_including(:read_only => false)
      )

      @api.rest_call(method)
    end


    it "takes an optional hash of arguments" do
      args = {:arg1 => 'arg1'}

      @api.should_receive(:api).with(
        anything,
        hash_including(args),
        anything,
        anything
      )

      @api.rest_call('anything', args)
    end

    it "always asks for JSON" do
      @api.should_receive(:api).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        anything
      )

      @api.rest_call('anything')
    end

    it "passes any options provided to the API" do
      options = {:a => 2}

      @api.should_receive(:api).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        hash_including(options)
      )

      @api.rest_call('anything', {}, options)
    end

    it "uses get by default" do
      @api.should_receive(:api).with(
        anything,
        anything,
        "get",
        anything
      )

      @api.rest_call('anything')
    end

    it "allows you to specify other http methods as the last argument" do
      method = 'bar'
      @api.should_receive(:api).with(
        anything,
        anything,
        method,
        anything
      )

      @api.rest_call('anything', {}, {}, method)
    end

    it "throws an APIError if the status code >= 400" do
      Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(500, '{"error_code": "An error occurred!"}', {}))
      lambda { @api.rest_call(KoalaTest.user1, {}) }.should raise_exception(Koala::Facebook::APIError)
    end
  end

  it "can use the beta tier" do
    @api.rest_call("fql.query", {:query => "select first_name from user where uid = #{KoalaTest.user2_id}"}, :beta => true)
  end
end

shared_examples_for "Koala RestAPI with an access token" do
  describe "#set_app_properties" do
    it "sends Facebook the properties JSON-encoded as :properties" do
      props = {:a => 2, :c => [1, 2, "d"]}
      @api.should_receive(:rest_call).with(anything, hash_including(:properties => MultiJson.dump(props)), anything, anything)
      @api.set_app_properties(props)
    end

    it "calls the admin.setAppProperties method" do
      @api.should_receive(:rest_call).with("admin.setAppProperties", anything, anything, anything)
      @api.set_app_properties({})
    end

    it "includes any other provided arguments" do
      args = {:c => 3, :d => "a"}
      @api.should_receive(:rest_call).with(anything, hash_including(args), anything, anything)
      @api.set_app_properties({:a => 2}, args)
    end

    it "includes any http_options provided" do
      opts = {:c => 3, :d => "a"}
      @api.should_receive(:rest_call).with(anything, anything, opts, anything)
      @api.set_app_properties({}, {}, opts)
    end
    
    it "makes a POST" do
      @api.should_receive(:rest_call).with(anything, anything, anything, "post")
      @api.set_app_properties({})
    end

    it "can set app properties using the app's access token" do
      oauth = Koala::Facebook::OAuth.new(KoalaTest.app_id, KoalaTest.secret)
      app_token = oauth.get_app_access_token
      @app_api = Koala::Facebook::API.new(app_token)
      @app_api.set_app_properties(KoalaTest.app_properties).should be_true
    end
  end
end


shared_examples_for "Koala RestAPI without an access token" do
  it "can't use set_app_properties" do
    lambda { @api.set_app_properties(:desktop => 0) }.should raise_error(Koala::Facebook::AuthenticationError)
  end
end
