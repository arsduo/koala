shared_examples_for "Koala GraphAPI" do
  # all Graph API instances should pass these tests, regardless of configuration

  # API
  it "never uses the rest api server" do
    Koala.should_receive(:make_request).with(
      anything,
      anything,
      anything,
      hash_not_including(:rest_api => true)
    ).and_return(Koala::HTTPService::Response.new(200, "", {}))

    @api.api("anything")
  end

  # GRAPH CALL
  describe "graph_call" do
    it "passes all arguments to the api method" do
      args = [KoalaTest.user1, {}, "get", {:a => :b}]
      @api.should_receive(:api).with(*args)
      @api.graph_call(*args)
    end

    it "throws an APIError if the result hash has an error key" do
      Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(500, '{"error": "An error occurred!"}', {}))
      lambda { @api.graph_call(KoalaTest.user1, {}) }.should raise_exception(Koala::Facebook::APIError)
    end

    it "passes the results through GraphCollection.evaluate" do
      result = {}
      @api.stub(:api).and_return(result)
      Koala::Facebook::GraphCollection.should_receive(:evaluate).with(result, @api)
      @api.graph_call("/me")
    end

    it "returns the results of GraphCollection.evaluate" do
      expected = {}
      @api.stub(:api).and_return([])
      Koala::Facebook::GraphCollection.should_receive(:evaluate).and_return(expected)
      @api.graph_call("/me").should == expected
    end

    it "returns the post_processing block's results if one is supplied" do
      other_result = [:a, 2, :three]
      block = Proc.new {|r| other_result}
      @api.stub(:api).and_return({})
      @api.graph_call("/me", {}, "get", {}, &block).should == other_result
    end
  end

  # SEARCH
  it "can search" do
    result = @api.search("facebook")
    result.length.should be_an(Integer)
  end

  # DATA
  # access public info

  # get_object
  it "gets public data about a user" do
    result = @api.get_object(KoalaTest.user1)
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should_not be_nil
  end

  it "gets public data about a Page" do
    result = @api.get_object(KoalaTest.page)
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should
  end

  it "returns [] from get_objects if passed an empty array" do
    results = @api.get_objects([])
    results.should == []
  end

  it "gets multiple objects" do
    results = @api.get_objects([KoalaTest.page, KoalaTest.user1])
    results.should have(2).items
  end

  it "gets multiple objects if they're a string" do
    results = @api.get_objects("contextoptional,#{KoalaTest.user1}")
    results.should have(2).items
  end

  it "can access a user's picture" do
    @api.get_picture(KoalaTest.user2).should =~ /http[s]*\:\/\//
  end

  it "can access a user's picture, given a picture type"  do
    @api.get_picture(KoalaTest.user2, {:type => 'large'}).should =~ /^http[s]*\:\/\//
  end

  it "can access connections from public Pages" do
    result = @api.get_connections(KoalaTest.page, "photos")
    result.should be_a(Array)
  end

  it "can access comments for a URL" do
    result = @api.get_comments_for_urls(["http://developers.facebook.com/blog/post/472"])
    (result["http://developers.facebook.com/blog/post/472"]).should
  end

  it "can access comments for 2 URLs" do
    result = @api.get_comments_for_urls(["http://developers.facebook.com/blog/post/490", "http://developers.facebook.com/blog/post/472"])
    (result["http://developers.facebook.com/blog/post/490"] && result["http://developers.facebook.com/blog/post/472"]).should
  end

  # SEARCH
  it "can search" do
    result = @api.search("facebook")
    result.length.should be_an(Integer)
  end

  # PAGING THROUGH COLLECTIONS
  # see also graph_collection_tests
  it "makes a request for a page when provided a specific set of page params" do
    query = [1, 2]
    @api.should_receive(:graph_call).with(*query)
    @api.get_page(query)
  end

  # Beta tier
  it "can use the beta tier" do
    result = @api.get_object(KoalaTest.user1, {}, :beta => true)
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should_not be_nil
  end

  # FQL
  describe "#fql_query" do
    it "makes a request to /fql" do
      @api.should_receive(:get_object).with("fql", anything, anything)
      @api.fql_query stub('query string')
    end

    it "passes a query argument" do
      query = stub('query string')
      @api.should_receive(:get_object).with(anything, hash_including(:q => query), anything)
      @api.fql_query(query)
    end

    it "passes on any other arguments provided" do
      args = {:a => 2}
      @api.should_receive(:get_object).with(anything, hash_including(args), anything)
      @api.fql_query("a query", args)
    end
  end

  describe "#fql_multiquery" do
    it "makes a request to /fql" do
      @api.should_receive(:get_object).with("fql", anything, anything)
      @api.fql_multiquery 'query string'
    end

    it "passes a queries argument" do
      queries = stub('query string')
      queries_json = "some JSON"
      MultiJson.stub(:dump).with(queries).and_return(queries_json)

      @api.should_receive(:get_object).with(anything, hash_including(:q => queries_json), anything)
      @api.fql_multiquery(queries)
    end

    it "simplifies the response format" do
      raw_results = [
        {"name" => "query1", "fql_result_set" => [1, 2, 3]},
        {"name" => "query2", "fql_result_set" => [:a, :b, :c]}
      ]
      expected_results = {
        "query1" => [1, 2, 3],
        "query2" => [:a, :b, :c]
      }

      @api.stub(:get_object).and_return(raw_results)
      results = @api.fql_multiquery({:query => true})
      results.should == expected_results
    end

    it "passes on any other arguments provided" do
      args = {:a => 2}
      @api.should_receive(:get_object).with(anything, hash_including(args), anything)
      @api.fql_multiquery("a query", args)
    end
  end
end


shared_examples_for "Koala GraphAPI with an access token" do
  it "gets private data about a user" do
    result = @api.get_object(KoalaTest.user1)
    # updated_time should be a pretty fixed test case
    result["updated_time"].should_not be_nil
  end

  it "gets data about 'me'" do
    result = @api.get_object("me")
    result["updated_time"].should
  end

  it "gets multiple objects" do
    result = @api.get_objects([KoalaTest.page, KoalaTest.user1])
    result.length.should == 2
  end
  it "can access connections from users" do
    result = @api.get_connections(KoalaTest.user2, "friends")
    result.length.should > 0
  end

  # PUT
  it "can write an object to the graph" do
    result = @api.put_wall_post("Hello, world, from the test suite!")
    @temporary_object_id = result["id"]
    @temporary_object_id.should_not be_nil
  end

  # DELETE
  it "can delete posts" do
    result = @api.put_wall_post("Hello, world, from the test suite delete method!")
    object_id_to_delete = result["id"]
    delete_result = @api.delete_object(object_id_to_delete)
    delete_result.should == true
  end

  it "can delete likes" do
    result = @api.put_wall_post("Hello, world, from the test suite delete like method!")
    @temporary_object_id = result["id"]
    @api.put_like(@temporary_object_id)
    delete_like_result = @api.delete_like(@temporary_object_id)
    delete_like_result.should == true
  end

  # additional put tests
  it "can verify messages posted to a wall" do
    message = "the cats are asleep"
    put_result = @api.put_wall_post(message)
    @temporary_object_id = put_result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the message we sent is the message that got posted
    get_result["message"].should == message
  end

  it "can post a message with an attachment to a feed" do
    result = @api.put_wall_post("Hello, world, from the test suite again!", {:name => "OAuth Playground", :link => "http://oauth.twoalex.com/"})
    @temporary_object_id = result["id"]
    @temporary_object_id.should_not be_nil
  end

  it "can post a message whose attachment has a properties dictionary" do
    url = KoalaTest.oauth_test_data["callback_url"]
    options = {
    "picture" => "#{KoalaTest.oauth_test_data["callback_url"]}/images/logo.png",
    "name" => "It's a big question",
    "type" => "link",
    "link" => KoalaTest.oauth_test_data["callback_url"],
    "properties" => [
        {"name" => "Link1'", "text" => "Left", "href" => url},
        {"name" => "other", "text" => "Straight ahead"}
      ]
    }

    result = @api.put_wall_post("body", options)
    @temporary_object_id = result["id"]
    @temporary_object_id.should_not be_nil
  end


  describe "#put_picture" do
    it "can post photos to the user's wall with an open file object" do
      content_type = "image/jpg"
      file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

      result = @api.put_picture(file, content_type)
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    it "can post photos to the user's wall without an open file object" do
      content_type = "image/jpg",
      file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")

      result = @api.put_picture(file_path, content_type)
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    it "can verify a photo posted to a user's wall" do
      content_type = "image/jpg",
      file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")

      expected_message = "This is the test message"

      result = @api.put_picture(file_path, content_type, :message => expected_message)
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil

      get_result = @api.get_object(@temporary_object_id)
      get_result["name"].should == expected_message
    end


    describe "using a URL instead of a file" do
      before :each do
        @url = "http://img.slate.com/images/redesign2008/slate_logo.gif"
      end

      it "can post photo to the user's wall using a URL" do
        result = @api.put_picture(@url)
        @temporary_object_id = result["id"]
        @temporary_object_id.should_not be_nil
      end

      it "can post photo to the user's wall using a URL and an additional param" do
        result = @api.put_picture(@url, :message => "my message")
        @temporary_object_id = result["id"]
        @temporary_object_id.should_not be_nil
      end
    end
  end

  describe "#put_video" do
    before :each do
      @cat_movie = File.join(File.dirname(__FILE__), "..", "fixtures", "cat.m4v")
      @content_type = "video/mpeg4"
    end

    it "sets options[:video] to true" do
      source = stub("UploadIO")
      Koala::UploadableIO.stub(:new).and_return(source)
      source.stub(:requires_base_http_service).and_return(false)
      Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(:video => true)).and_return(Koala::HTTPService::Response.new(200, "[]", {}))
      @api.put_video("foo")
    end

    it "can post videos to the user's wall with an open file object" do
      file = File.open(@cat_movie)

      result = @api.put_video(file, @content_type)
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end


    it "can post videos to the user's wall without an open file object" do
      result = @api.put_video(@cat_movie, @content_type)
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    # note: Facebook doesn't post videos immediately to the wall, due to processing time
    # during which get_object(video_id) will return false
    # hence we can't do the same verify test we do for photos
  end

  it "can verify a message with an attachment posted to a feed" do
    attachment = {"name" => "OAuth Playground", "link" => "http://oauth.twoalex.com/"}
    result = @api.put_wall_post("Hello, world, from the test suite again!", attachment)
    @temporary_object_id = result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the result we fetch includes all the parameters we sent
    it_matches = attachment.inject(true) {|valid, param| valid && (get_result[param[0]] == attachment[param[0]])}
    it_matches.should == true
  end

  it "can comment on an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_result = @api.put_comment(@temporary_object_id, "it's my comment!")
    comment_result.should_not be_nil
  end

  it "can verify a comment posted about an object" do
    message_text = "Hello, world, from the test suite, testing comments again!"
    result = @api.put_wall_post(message_text)
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_text = "it's my comment!"
    comment_result = @api.put_comment(@temporary_object_id, comment_text)
    get_result = @api.get_object(comment_result["id"])

    # make sure the text of the comment matches what we sent
    get_result["message"].should == comment_text
  end

  it "can like an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing liking!")
    @temporary_object_id = result["id"]
    like_result = @api.put_like(@temporary_object_id)
    like_result.should be_true
  end

  # Page Access Token Support
  describe "#get_page_access_token" do
    it "gets the page object with the access_token field" do
      # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
      @api.should_receive(:api).with("my_page", hash_including({:fields => "access_token"}), "get", anything)
      @api.get_page_access_token("my_page")
    end

    it "merges in any other arguments" do
      # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
      args = {:a => 3}
      @api.should_receive(:api).with("my_page", hash_including(args), "get", anything)
      @api.get_page_access_token("my_page", args)
    end
  end

  describe "#set_app_restrictions" do
    before :all do
      oauth = Koala::Facebook::OAuth.new(KoalaTest.app_id, KoalaTest.secret)
      app_token = oauth.get_app_access_token
      @app_api = Koala::Facebook::API.new(app_token)
      @restrictions = {"age_distr" => "13+"}
    end

    it "makes a POST to /app_id" do
      @app_api.should_receive(:graph_call).with(KoalaTest.app_id, anything, "post", anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
    end

    it "JSON-encodes the restrictions" do
      @app_api.should_receive(:graph_call).with(anything, hash_including(:restrictions => MultiJson.dump(@restrictions)), anything, anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
    end

    it "includes the other arguments" do
      args = {:a => 2}
      @app_api.should_receive(:graph_call).with(anything, hash_including(args), anything, anything)
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions, args)
    end

    it "works" do
      @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions).should be_true
    end
  end

  it "can access public information via FQL" do
    result = @api.fql_query("select uid, first_name from user where uid = #{KoalaTest.user2_id}")
    result.size.should == 1
    result.first['first_name'].should == KoalaTest.user2_name
    result.first['uid'].should == KoalaTest.user2_id.to_i
  end

  it "can access public information via FQL.multiquery" do
    result = @api.fql_multiquery(
      :query1 => "select uid, first_name from user where uid = #{KoalaTest.user2_id}",
      :query2 => "select uid, first_name from user where uid = #{KoalaTest.user1_id}"
    )
    result.size.should == 2
    # this should check for first_name, but there's an FB bug currently
    result["query1"].first['uid'].should == KoalaTest.user2_id.to_i
    # result["query1"].first['first_name'].should == KoalaTest.user2_name
    result["query2"].first['first_name'].should == KoalaTest.user1_name
  end

  it "can access protected information via FQL" do
    # Tests agains the permissions fql table

    # get the current user's ID
    # we're sneakily using the Graph API, which should be okay since it has its own tests
    g = Koala::Facebook::API.new(@token)
    id = g.get_object("me", :fields => "id")["id"]

    # now send a query about your permissions
    result = @api.fql_query("select read_stream from permissions where uid = #{id}")

    result.size.should == 1
    # we've verified that you have read_stream permissions, so we can test against that
    result.first["read_stream"].should == 1
  end

  it "can access protected information via FQL.multiquery" do
    result = @api.fql_multiquery(
      :query1 => "select post_id from stream where source_id = me()",
      :query2 => "select fromid from comment where post_id in (select post_id from #query1)",
      :query3 => "select uid, name from user where uid in (select fromid from #query2)"
    )
    result.size.should == 3
    result.keys.should include("query1", "query2", "query3")
  end

  # test all methods to make sure they pass data through to the API
  # we run the tests here (rather than in the common shared example group)
  # since some require access tokens
  describe "HTTP options" do
    # Each of the below methods should take an options hash as their last argument
    # ideally we'd use introspection to determine how many arguments a method has
    # but some methods require specially formatted arguments for processing
    # (and anyway, Ruby 1.8's arity method fails (for this) for methods w/ 2+ optional arguments)
    # (Ruby 1.9's parameters method is perfect, but only in 1.9)
    # so we have to double-document
    {
      :get_object => 3, :put_object => 4, :delete_object => 2,
      :get_connections => 4, :put_connections => 4, :delete_connections => 4,
      :put_wall_post => 4,
      :put_comment => 3,
      :put_like => 2, :delete_like => 2,
      :search => 3,
      :set_app_restrictions => 4,
      :get_page_access_token => 3,
      :fql_query => 3, :fql_multiquery => 3,
      # methods that have special arguments
      :get_comments_for_urls => [["url1", "url2"], {}],
      :put_picture => ["x.jpg", "image/jpg", {}, "me"],
      :put_video => ["x.mp4", "video/mpeg4", {}, "me"],
      :get_objects => [["x"], {}]
    }.each_pair do |method_name, params|
      it "passes http options through for #{method_name}" do
        options = {:a => 2}
        # graph call should ultimately receive options as the fourth argument
        @api.should_receive(:graph_call).with(anything, anything, anything, options)

        # if we supply args, use them (since some methods process params)
        # the method should receive as args n-1 anythings and then options
        args = (params.is_a?(Integer) ? ([{}] * (params - 1)) : params) + [options]

        @api.send(method_name, *args)
      end
    end

    # also test get_picture, which merges a parameter into options
    it "passes http options through for get_picture" do
      options = {:a => 2}
      # graph call should ultimately receive options as the fourth argument
      @api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options)).and_return({})
      @api.send(:get_picture, "x", {}, options)
    end
  end
end


# GraphCollection
shared_examples_for "Koala GraphAPI with GraphCollection" do
  describe "when getting a collection" do
    # GraphCollection methods
    it "gets a GraphCollection when getting connections" do
      @result = @api.get_connections(KoalaTest.page, "photos")
      @result.should be_a(Koala::Facebook::GraphCollection)
    end

    it "returns nil if the get_collections call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.get_connections(KoalaTest.page, "photos").should be_nil
    end

    it "gets a GraphCollection when searching" do
      result = @api.search("facebook")
      result.should be_a(Koala::Facebook::GraphCollection)
    end

    it "returns nil if the search call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.search("facebook").should be_nil
    end

    it "gets a GraphCollection when paging through results" do
      @results = @api.get_page(["search", {"q"=>"facebook", "limit"=>"25", "until"=> KoalaTest.search_time}])
      @results.should be_a(Koala::Facebook::GraphCollection)
    end

    it "returns nil if the page call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.get_page(["search", {"q"=>"facebook", "limit"=>"25", "until"=> KoalaTest.search_time}]).should be_nil
    end
  end
end


shared_examples_for "Koala GraphAPI without an access token" do
  it "can't get private data about a user" do
    result = @api.get_object(KoalaTest.user1)
    # updated_time should be a pretty fixed test case
    result["updated_time"].should be_nil
  end

  it "can't get data about 'me'" do
    lambda { @api.get_object("me") }.should raise_error(Koala::Facebook::ClientError)
  end

  it "can't access connections from users" do
    lambda { @api.get_connections(KoalaTest.user2, "friends") }.should raise_error(Koala::Facebook::ClientError)
  end

  it "can't put an object" do
    lambda { @result = @api.put_connections(KoalaTest.user2, "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::AuthenticationError)
    # legacy put_object syntax
    lambda { @result = @api.put_object(KoalaTest.user2, "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::AuthenticationError)
  end

  # these are not strictly necessary as the other put methods resolve to put_connections,
  # but are here for completeness
  it "can't post to a feed" do
    (lambda do
      attachment = {:name => "OAuth Playground", :link => "http://oauth.twoalex.com/"}
      @result = @api.put_wall_post("Hello, world", attachment, "contextoptional")
    end).should raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't comment on an object" do
    # random public post on the ContextOptional wall
    lambda { @result = @api.put_comment("7204941866_119776748033392", "The hackathon was great!") }.should raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't like an object" do
    lambda { @api.put_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::AuthenticationError)
  end

  # DELETE
  it "can't delete posts" do
    # test post on the Ruby SDK Test application
    lambda { @result = @api.delete_object("115349521819193_113815981982767") }.should raise_error(Koala::Facebook::AuthenticationError)
  end

  it "can't delete a like" do
    lambda { @api.delete_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::AuthenticationError)
  end

  # FQL_QUERY
  describe "when making a FQL request" do
    it "can access public information via FQL" do
      result = @api.fql_query("select uid, first_name from user where uid = #{KoalaTest.user2_id}")
      result.size.should == 1
      result.first['first_name'].should == KoalaTest.user2_name
    end

    it "can access public information via FQL.multiquery" do
      result = @api.fql_multiquery(
        :query1 => "select uid, first_name from user where uid = #{KoalaTest.user2_id}",
        :query2 => "select uid, first_name from user where uid = #{KoalaTest.user1_id}"
      )
      result.size.should == 2
      result["query1"].first['first_name'].should == KoalaTest.user2_name
      result["query2"].first['first_name'].should == KoalaTest.user1_name
    end

    it "can't access protected information via FQL" do
      lambda { @api.fql_query("select read_stream from permissions where uid = #{KoalaTest.user2_id}") }.should raise_error(Koala::Facebook::APIError)
    end

    it "can't access protected information via FQL.multiquery" do
      lambda {
        @api.fql_multiquery(
          :query1 => "select post_id from stream where source_id = me()",
          :query2 => "select fromid from comment where post_id in (select post_id from #query1)",
          :query3 => "select uid, name from user where uid in (select fromid from #query2)"
        )
      }.should raise_error(Koala::Facebook::APIError)
    end
  end
end
