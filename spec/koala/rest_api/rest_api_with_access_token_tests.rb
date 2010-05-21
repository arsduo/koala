shared_examples_for "Koala RestAPI with an access token" do
  # FQL
  it "should be able to access public information via FQL" do
    result = @api.fql_query('select first_name from user where uid = 216743')
    result.size.should == 1
    result.first['first_name'].should == 'Chris'
  end

  it "should be able to access protected information via FQL" do
    # Tests agains the permissions fql table
    
    # get the current user's ID
    # we're sneakily using the Graph API, which should be okay since it has its own tests
    g = Koala::Facebook::GraphAPI.new(@token)
    id = g.get_object("me", :fields => "id")["id"]

    # now send a query about your permissions
    result = @api.fql_query("select read_stream from permissions where uid = #{id}")

    result.size.should == 1
    # we assume that you have read_stream permissions, so we can test against that
    # (should we keep this?)
    result.first["read_stream"].should == 1
  end
end

class FacebookRestAPIWithAccessTokenTests < Test::Unit::TestCase
  describe "Koala RestAPI with an access token" do
    it_should_behave_like "live testing examples"
    it_should_behave_like "Koala RestAPI with an access token"
    
    before :each do
      @api = Koala::Facebook::RestAPI.new(@token)
    end
  end
end