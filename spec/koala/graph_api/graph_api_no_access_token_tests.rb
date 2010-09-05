shared_examples_for "Koala GraphAPI without an access token" do
  it "should get public data about a user" do
    result = @api.get_object("koppel")
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should
  end

  it "should not get private data about a user" do
    result = @api.get_object("koppel")
    # updated_time should be a pretty fixed test case
    result["updated_time"].should be_nil
  end

  it "should get public data about a Page" do
    result = @api.get_object("contextoptional")
    # the results should have an ID and a name, among other things
    (result["id"] && result["name"]).should
  end

  it "should not be able to get data about 'me'" do
    lambda { @api.get_object("me") }.should raise_error(Koala::Facebook::APIError)
  end

  it "should be able to get multiple objects" do
    results = @api.get_objects(["contextoptional", "naitik"])
    results.length.should == 2
  end

  it "shouldn't be able to access connections from users" do
    lambda { @api.get_connections("lukeshepard", "likes") }.should raise_error(Koala::Facebook::APIError)
  end

  it "should be able to access a user's picture" do
    @api.get_picture("chris.baclig").should =~ /http\:\/\//
  end

  it "should be able to access a user's picture, given a picture type"  do
    @api.get_picture("chris.baclig", {:type => 'large'}).should =~ /^http\:\/\//
  end

  it "should be able to access connections from public Pages" do
    result = @api.get_connections("contextoptional", "likes")
    result.should be_a(Array)
  end

  it "should not be able to put an object" do
    lambda { @result = @api.put_object("lukeshepard", "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::APIError)
    puts "Error!  Object #{@result.inspect} somehow put onto Luke Shepard's wall!" if @result
  end

  # these are not strictly necessary as the other put methods resolve to put_object, but are here for completeness
  it "should not be able to post to a feed" do
    (lambda do
      attachment = {:name => "Context Optional", :link => "http://www.contextoptional.com/"}
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

  # GraphCollection
  describe "when getting a collection" do
    before(:each) do
      @result = @api.get_connections("contextoptional", "likes")
    end
    
    it "should get a GraphCollection when getting connections" do
      @result.should be_a(Koala::Facebook::GraphCollection)
    end
    
    it "should have a read-only paging attribute" do
      lambda { @result.paging }.should_not raise_error
      lambda { @result.paging = "paging" }.should raise_error(NoMethodError)
    end
    
    describe "and getting a whole page" do
      before(:each) do
        @second_page = stub("page of Fb graph results")
        @base = stub("base")
        @args = stub("args")
        @page_of_results = stub("page of results")
      end
      
      it "should return the previous page of results" do
        @result.should_receive(:previous_page_params).and_return([@base, @args])
        @api.should_receive(:graph_call).with(@base, @args).and_return(@second_page)
        Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page).and_return(@page_of_results)
        
        @result.previous_page(@api).should == @page_of_results
      end
      
      it "should return the next page of results" do
        @result.should_receive(:next_page_params).and_return([@base, @args])
        @api.should_receive(:graph_call).with(@base, @args).and_return(@second_page)
        Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page).and_return(@page_of_results)
        
        @result.next_page(@api).should == @page_of_results        
      end
      
      it "should return nil it there are no other pages" do
        %w{next previous}.each do |this|
          @result.should_receive("#{this}_page_params".to_sym).and_return(nil)
          @result.send("#{this}_page", @api).should == nil
        end
      end
    end
    
    describe "and parsing page paramters" do
      before(:each) do
        @graph_collection = Koala::Facebook::GraphCollection.new({"data" => []})
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
  
  # DELETE
  it "should not be able to delete posts" do 
    # test post on the Ruby SDK Test application
    lambda { @result = @api.delete_object("115349521819193_113815981982767") }.should raise_error(Koala::Facebook::APIError)
  end

  # SEARCH
  it "should be able to search" do
    result = @api.search("facebook")
    result["data"].should be_an(Array)
  end

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
end

class FacebookNoAccessTokenTests < Test::Unit::TestCase
  describe "Koala GraphAPI without an access token" do
    before :each do
      @api = Koala::Facebook::GraphAPI.new
    end  
    
    it_should_behave_like "Koala GraphAPI without an access token"
  end
end
  