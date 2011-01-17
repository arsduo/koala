class GraphAndRestAPINoTokenTests < Test::Unit::TestCase
  describe "Koala GraphAndRestAPI without an access token" do
    before(:each) do
      @api = Koala::Facebook::GraphAndRestAPI.new
    end
    
    it_should_behave_like "Koala RestAPI without an access token"
    it_should_behave_like "Koala GraphAPI without an access token"
  end
end