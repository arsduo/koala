shared_examples_for "Koala RestAPI without an access token" do
  # REST_CALL
  describe "when making a rest request" do
    it "should use the proper path" do
      method = stub('methodName')
      @api.should_receive(:api).with(
        "method/#{method}",
        anything,
        anything,
        anything
      )
      
      @api.rest_call(method)  
    end
    
    it "should always use the rest api" do
      @api.should_receive(:api).with(
        anything,
        anything,
        anything,
        :rest_api => true
      )  
      
      @api.rest_call('anything')
    end
    
    it "should take an optional hash of arguments" do
      args = {:arg1 => 'arg1'}
      
      @api.should_receive(:api).with(
        anything,
        hash_including(args),
        anything,
        anything
      )
      
      @api.rest_call('anything', args)
    end
    
    it "should always ask for JSON" do
      @api.should_receive(:api).with(
        anything,
        hash_including('format' => 'json'),
        anything,
        anything
      )
      
      @api.rest_call('anything')
    end
  end 

  # FQL_QUERY
  describe "when making a FQL request" do
    it "should call fql.query method" do
      @api.should_receive(:rest_call).with(
        "fql.query", 
        anything
      ).and_return(Koala::Response.new(200, "2", {}))
      
      @api.fql_query stub('query string')
    end
    
    it "should pass a query argument" do
      query = stub('query string')
      
      @api.should_receive(:rest_call).with(
        anything,
        hash_including("query" => query)
      )
      
      @api.fql_query(query)
    end
  
    it "should be able to access public information via FQL" do
      @result = @api.fql_query("select first_name from user where uid = 216743")
      @result.size.should == 1
      @result.first["first_name"].should == "Chris"
    end
    
    it "should not be able to access protected information via FQL" do
      lambda { @api.fql_query("select read_stream from permissions where uid = 216743") }.should raise_error(Koala::Facebook::APIError)
    end
  end
end

class FacebookRestAPINoAccessTokenTest < Test::Unit::TestCase 
  describe "Koala RestAPI without an access token" do
    before :each do
      @api = Koala::Facebook::RestAPI.new
    end
    
    it_should_behave_like "Koala RestAPI without an access token" 
  end
end