require 'spec_helper'

describe "Koala::Facebook::GraphAPI" do  
  context "with an access token" do
    before :each do
      @api = Koala::Facebook::GraphAPI.new(@token)
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end