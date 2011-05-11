shared_examples_for "Koala GraphAPI" do
  # all Graph API instances should pass these tests, regardless of configuration

  # API
  it "should never use the rest api server" do
    Koala.should_receive(:make_request).with(
      anything,
      anything,
      anything,
      hash_not_including(:rest_api => true)
    ).and_return(Koala::Response.new(200, "", {}))

    @api.api("anything")
  end

  # GRAPH CALL
  describe "graph_call" do
    it "should pass all arguments to the api method" do
      args = ["koppel", {}, "get", {:a => :b}]

      @api.should_receive(:api).with(*args)

      @api.graph_call(*args)
    end

    it "should throw an APIError if the result hash has an error key" do
      Koala.stub(:make_request).and_return(Koala::Response.new(500, {"error" => "An error occurred!"}, {}))
      lambda { @api.graph_call("koppel", {}) }.should raise_exception(Koala::Facebook::APIError)
    end
  end

  # SEARCH
  it "should be able to search" do
    result = @api.search("facebook")
    result.length.should be_an(Integer)
  end

  # DATA
  # access public info

  # get_object
  it "should get public data about a user" do
    result = @api.get_object("koppel")
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should_not be_nil
  end

  it "should get public data about a Page" do
    result = @api.get_object("contextoptional")
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should
  end

  it "should be able to get multiple objects" do
    results = @api.get_objects(["contextoptional", "naitik"])
    results.length.should == 2
  end

  it "should be able to access a user's picture" do
    @api.get_picture("chris.baclig").should =~ /http[s]*\:\/\//
  end

  it "should be able to access a user's picture, given a picture type"  do
    @api.get_picture("lukeshepard", {:type => 'large'}).should =~ /^http[s]*\:\/\//
  end

  it "should be able to access connections from public Pages" do
    result = @api.get_connections("contextoptional", "photos")
    result.should be_a(Array)
  end

  # SEARCH
  it "should be able to search" do
    result = @api.search("facebook")
    result.length.should be_an(Integer)
  end

  # PAGING THROUGH COLLECTIONS
  # see also graph_collection_tests
  it "should make a request for a page when provided a specific set of page params" do
    query = [1, 2]
    @api.should_receive(:graph_call).with(*query)
    @api.get_page(query)
  end
end


shared_examples_for "Koala GraphAPI with an access token" do

  it "should get private data about a user" do
    result = @api.get_object("koppel")
    # updated_time should be a pretty fixed test case
    result["updated_time"].should_not be_nil
  end

  it "should get data about 'me'" do
    result = @api.get_object("me")
    result["updated_time"].should
  end

  it 'should be able to get data about a user and me at the same time' do
    me, koppel = @api.batch do
      @api.get_object('me')
      @api.get_object('koppel')
    end
    me['id'].should_not be_nil
    koppel['id'].should_not be_nil
  end

  it 'should be able to make a get_picture call inside of a batch' do
    pictures = @api.batch do
      @api.get_picture('me')
    end
    pictures.first.should_not be_empty
  end

  it 'should be able to make mixed calls inside of a batch' do
    me, friends = @api.batch do
      @api.get_object('me')
      @api.get_connections('me', 'friends')
    end
    me['id'].should_not be_nil
    friends.should be_a(Array)
  end

  it "should be able to get multiple objects" do
    result = @api.get_objects(["contextoptional", "naitik"])
    result.length.should == 2
  end
  it "should be able to access connections from users" do
    result = @api.get_connections("lukeshepard", "likes")
    result.length.should > 0
  end

  # PUT
  it "should be able to write an object to the graph" do
    result = @api.put_wall_post("Hello, world, from the test suite!")
    @temporary_object_id = result["id"]
    @temporary_object_id.should_not be_nil
  end

  # DELETE
  it "should be able to delete posts" do
    result = @api.put_wall_post("Hello, world, from the test suite delete method!")
    object_id_to_delete = result["id"]
    delete_result = @api.delete_object(object_id_to_delete)
    delete_result.should == true
  end

  it "should be able to delete likes" do
    result = @api.put_wall_post("Hello, world, from the test suite delete method!")
    @temporary_object_id = result["id"]
    @api.put_like(@temporary_object_id)
    delete_like_result = @api.delete_like(@temporary_object_id)
    delete_like_result.should == true
  end

  # additional put tests
  it "should be able to verify messages posted to a wall" do
    message = "the cats are asleep"
    put_result = @api.put_wall_post(message)
    @temporary_object_id = put_result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the message we sent is the message that got posted
    get_result["message"].should == message
  end

  it "should be able to post a message with an attachment to a feed" do
    result = @api.put_wall_post("Hello, world, from the test suite again!", {:name => "OAuth Playground", :link => "http://oauth.twoalex.com/"})
    @temporary_object_id = result["id"]
    @temporary_object_id.should_not be_nil
  end

  it "should be able to post photos to the user's wall with an open file object" do
    content_type = "image/jpg"      
    file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))
    
    result = @api.put_picture(file, content_type)
    @temporary_object_id = result["id"] 
    @temporary_object_id.should_not be_nil
  end
  
  it "should be able to post photos to the user's wall without an open file object" do
    content_type = "image/jpg",
    file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")
    
    result = @api.put_picture(file_path, content_type)
    @temporary_object_id = result["id"] 
    @temporary_object_id.should_not be_nil
  end
    
  it "should be able to verify a photo posted to a user's wall" do
    content_type = "image/jpg",
    file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")
    
    expected_message = "This is the test message"
    
    result = @api.put_picture(file_path, content_type, :message => expected_message)
    @temporary_object_id = result["id"] 
    @temporary_object_id.should_not be_nil
    
    get_result = @api.get_object(@temporary_object_id)
    get_result["name"].should == expected_message
  end

  it "should be able to verify a message with an attachment posted to a feed" do
    attachment = {"name" => "OAuth Playground", "link" => "http://oauth.twoalex.com/"}
    result = @api.put_wall_post("Hello, world, from the test suite again!", attachment)
    @temporary_object_id = result["id"]
    get_result = @api.get_object(@temporary_object_id)

    # make sure the result we fetch includes all the parameters we sent
    it_matches = attachment.inject(true) {|valid, param| valid && (get_result[param[0]] == attachment[param[0]])}
    it_matches.should == true
  end

  it "should be able to comment on an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_result = @api.put_comment(@temporary_object_id, "it's my comment!")
    comment_result.should_not be_nil
  end

  it "should be able to verify a comment posted about an object" do
    message_text = "Hello, world, from the test suite, testing comments!"
    result = @api.put_wall_post(message_text)
    @temporary_object_id = result["id"]

    # this will be deleted when the post gets deleted
    comment_text = "it's my comment!"
    comment_result = @api.put_comment(@temporary_object_id, comment_text)
    get_result = @api.get_object(comment_result["id"])

    # make sure the text of the comment matches what we sent
    get_result["message"].should == comment_text
  end

  it "should be able to like an object" do
    result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
    @temporary_object_id = result["id"]
    like_result = @api.put_like(@temporary_object_id)
    like_result.should be_true
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
      # methods that have special arguments
      :put_picture => ["x.jpg", "image/jpg", {}, "me"],
      :get_objects => [["x"], {}]
    }.each_pair do |method_name, params|
      it "should pass http options through for #{method_name}" do
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
    it "should pass http options through for get_picture" do
      options = {:a => 2}
      # graph call should ultimately receive options as the fourth argument
      @api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options)).and_return({})
      @api.send(:get_picture, "x", {}, options)
    end
  end
end


# GraphCollection
shared_examples_for "Koala GraphAPI with GraphCollection" do

  it "should create an array-like object" do
    call = @api.graph_call("contextoptional/photos")
    Koala::Facebook::GraphCollection.new(call, @api).should be_an(Array)
  end

  describe "when getting a collection" do
    # GraphCollection methods
    it "should get a GraphCollection when getting connections" do
      @result = @api.get_connections("contextoptional", "photos")
      @result.should be_a(Koala::Facebook::GraphCollection)
    end

    it "should return nil if the get_collections call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.get_connections("contextoptional", "photos").should be_nil
    end

    it "should get a GraphCollection when searching" do
      result = @api.search("facebook")
      result.should be_a(Koala::Facebook::GraphCollection)
    end

    it "should return nil if the search call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.search("facebook").should be_nil
    end

    it "should get a GraphCollection when paging through results" do
      @results = @api.get_page(["search", {"q"=>"facebook", "limit"=>"25", "until"=>"2010-09-23T21:17:33+0000"}])
      @results.should be_a(Koala::Facebook::GraphCollection)
    end

    it "should return nil if the page call fails with nil" do
      # this happens sometimes
      @api.should_receive(:graph_call).and_return(nil)
      @api.get_page(["search", {"q"=>"facebook", "limit"=>"25", "until"=>"2010-09-23T21:17:33+0000"}]).should be_nil
    end

    # GraphCollection attributes
    describe "the GraphCollection" do
      before(:each) do
        @result = @api.get_connections("contextoptional", "photos")
      end

      it "should have a read-only paging attribute" do
        lambda { @result.paging }.should_not raise_error
        lambda { @result.paging = "paging" }.should raise_error(NoMethodError)
      end

      describe "when getting a whole page" do
        before(:each) do
          @second_page = stub("page of Fb graph results")
          @base = stub("base")
          @args = stub("args")
          @page_of_results = stub("page of results")
        end

        it "should return the previous page of results" do
          @result.should_receive(:previous_page_params).and_return([@base, @args])
          @api.should_receive(:graph_call).with(@base, @args).and_yield(@second_page)
          Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)

          @result.previous_page.should == @page_of_results
        end

        it "should return the next page of results" do
          @result.should_receive(:next_page_params).and_return([@base, @args])
          @api.should_receive(:graph_call).with(@base, @args).and_yield(@second_page)
          Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)

          @result.next_page.should == @page_of_results
        end

        it "should return nil it there are no other pages" do
          %w{next previous}.each do |this|
            @result.should_receive("#{this}_page_params".to_sym).and_return(nil)
            @result.send("#{this}_page").should == nil
          end
        end
      end

      describe "when parsing page paramters" do
        before(:each) do
          @graph_collection = Koala::Facebook::GraphCollection.new({"data" => []}, Koala::Facebook::GraphAPI.new)
        end

        it "should return the base as the first array entry" do
          base = "url_path"
          @graph_collection.parse_page_url("anything.com/#{base}?anything").first.should == base
        end

        it "should return the arguments as a hash as the last array entry" do
          args_hash = {"one" => "val_one", "two" => "val_two"}
          @graph_collection.parse_page_url("anything.com/anything?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").last.should == args_hash
        end
      end
    end
  end
end


shared_examples_for "Koala GraphAPI without an access token" do

  it "should not get private data about a user" do
    result = @api.get_object("koppel")
    # updated_time should be a pretty fixed test case
    result["updated_time"].should be_nil
  end

  it "should not be able to get data about 'me'" do
    lambda { @api.get_object("me") }.should raise_error(Koala::Facebook::APIError)
  end

  it "shouldn't be able to access connections from users" do
    lambda { @api.get_connections("lukeshepard", "likes") }.should raise_error(Koala::Facebook::APIError)
  end

  it "should not be able to put an object" do
    lambda { @result = @api.put_object("lukeshepard", "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::APIError)
    puts "Error!  Object #{@result.inspect} somehow put onto Luke Shepard's wall!" if @result
  end

  # these are not strictly necessary as the other put methods resolve to put_object, but are here for completeness
  it "should not be able to post to a feed" do
    (lambda do
      attachment = {:name => "OAuth Playground", :link => "http://oauth.twoalex.com/"}
      @result = @api.put_wall_post("Hello, world", attachment, "contextoptional")
    end).should raise_error(Koala::Facebook::APIError)
    puts "Error!  Object #{@result.inspect} somehow put onto Context Optional's wall!" if @result
  end

  it "should not be able to comment on an object" do
    # random public post on the ContextOptional wall
    lambda { @result = @api.put_comment("7204941866_119776748033392", "The hackathon was great!") }.should raise_error(Koala::Facebook::APIError)
    puts "Error!  Object #{@result.inspect} somehow commented on post 7204941866_119776748033392!" if @result
  end

  it "should not be able to like an object" do
    lambda { @api.put_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::APIError)
  end

  # DELETE
  it "should not be able to delete posts" do
    # test post on the Ruby SDK Test application
    lambda { @result = @api.delete_object("115349521819193_113815981982767") }.should raise_error(Koala::Facebook::APIError)
  end

  it "should not be able to delete a like" do
    lambda { @api.delete_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::APIError)
  end
end
