class FacebookRestAPIWithAccessTokenTests < Test::Unit::TestCase
  describe "Koala GraphAndRestAPI with an access token" do
    before :each do
      token = $testing_data["oauth_token"]
      raise Exception, "Must supply access token to run FacebookRestAPIWithAccessTokenTests!" unless token
      @graph = Koala::Facebook::GraphAndRestAPI.new(token)
    end

    # FQL
    it "should be able to access public information via FQL" do
      result = @graph.fql_query('select first_name from user where uid = 216743')
      result.size.should == 1
      result.first['first_name'].should == 'Chris'
    end

    it "should be able to access protected information via FQL" do
      # Tests agains the permissions fql table

      # get the current user's ID
      id = @graph.get_object("me", :fields => "id")["id"]

      # now send a query about your permissions
      result = @graph.fql_query("select read_stream from permissions where uid = #{id}")
  
      result.size.should == 1
      # we assume that you have read_stream permissions, so we can test against that
      # (should we keep this?)
      result.first["read_stream"].should == 1
    end
  end
end