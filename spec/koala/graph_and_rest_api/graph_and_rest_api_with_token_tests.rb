class GraphAndRestAPIWithTokenTests < Test::Unit::TestCase
  describe "Koala GraphAndRestAPI without an access token" do
    it_should_behave_like "live testing examples"
    it_should_behave_like "Koala RestAPI with an access token"
    it_should_behave_like "Koala GraphAPI with an access token"
    
    before(:each) do
      @api = Koala::Facebook::GraphAndRestAPI.new(@token)
    end
  end
end