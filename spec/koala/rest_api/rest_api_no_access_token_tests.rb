shared_examples_for "Koala RestAPI without an access token" do
  # FQL_QUERY
  describe "when making a FQL request" do
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

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"
  end
end