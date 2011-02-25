class GraphAndRestAPIWithTokenTests < Test::Unit::TestCase
  describe "Koala GraphAndRestAPI without an access token" do
    include LiveTestingDataHelper

    before(:each) do
      @api = Koala::Facebook::GraphAndRestAPI.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end