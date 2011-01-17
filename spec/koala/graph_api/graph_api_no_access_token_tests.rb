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
    result = @api.get_connections("contextoptional", "photos")
    result.should be_a(Array)
  end
  
  # paging
  # see also graph_collection_tests
  it "should make a request for a page when provided a specific set of page params" do
    query = [1, 2]
    @api.should_receive(:graph_call).with(*query)
    @api.get_page(query)
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
  
  # DELETE
  it "should not be able to delete posts" do 
    # test post on the Ruby SDK Test application
    lambda { @result = @api.delete_object("115349521819193_113815981982767") }.should raise_error(Koala::Facebook::APIError)
  end
<<<<<<< HEAD
  
  it "should not be able to delete a like" do
    lambda { @api.delete_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::APIError)
=======

  # SEARCH
  it "should be able to search" do
    result = @api.search("facebook")
    result.length.should be_an(Integer)
  end

  it_should_behave_like "Koala GraphAPI with GraphCollection"
  
  # API
  it "should never use the rest api server" do
    Koala.should_receive(:make_request).with(
      anything,
      anything,
      anything,
      hash_not_including(:rest_api => true)
    ).and_return(Koala::Response.new(200, "", {}))      
    
    @api.api("anything")
>>>>>>> parent of b5cb835... Restructured the test suite, pulling duplicate GraphAPI and RestAPI tests into a single common suite and adding tests for the api-read endpoint.
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
  
