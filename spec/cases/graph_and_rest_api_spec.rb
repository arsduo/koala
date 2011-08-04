require 'spec_helper'

describe "Koala::Facebook::GraphAndRestAPI" do
  describe "with an access token" do
    before(:each) do
      @api = Koala::Facebook::GraphAndRestAPI.new(@token)
    end

    it_should_behave_like "Koala RestAPI"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end