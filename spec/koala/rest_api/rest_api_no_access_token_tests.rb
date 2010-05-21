class FacebookRestAPINoAccessTokenTest < Test::Unit::TestCase
  
  describe "Koala RestAPI without an access token" do
    before :each do
      @graph = Koala::Facebook::RestAPI.new
    end
=begin
    # TODO: Create new rest_call method rather than 
    # overriding api, since it doesn't allow
    # the REST API module to be included into the
    # same object as the Graph API module
    
    # api
    it "should always use the rest api" do
      Koala.should_receive(:make_request).with(
        anything,
        anything,
        anything,
        hash_including(:rest_api => true)
      )
      
      @graph.api("anything")
    end
    
    it "should always ask for JSON" do
      Koala.should_receive(:make_request).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        anything
      )
      
      @graph.api("anything")
    end
=end

    # fql_query
    it "should pass the proper arguments" do
      query = "query"
      
      @graph.should_receive(:api).with(
        "method/fql.query", 
        hash_including("query" => query), 
        "get",
        hash_including(:rest_api => true)
      ).and_return(Koala::Response.new(200, "2", {}))
      
      @graph.fql_query(query)
    end
    
    it "should be able to access public information via FQL" do
      @result = @graph.fql_query("select first_name from user where uid = 216743")
      @result.size.should == 1
      @result.first["first_name"].should == "Chris"
    end
    
    it "should not be able to access protected information via FQL" do
      lambda { @graph.fql_query("select read_stream from permissions where uid = 216743") }.should raise_error(Koala::Facebook::APIError)
    end
  end
  
end