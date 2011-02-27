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
    @api.get_picture("chris.baclig").should =~ /http\:\/\//
  end

  it "should be able to access a user's picture, given a picture type"  do
    @api.get_picture("chris.baclig", {:type => 'large'}).should =~ /^http\:\/\//
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