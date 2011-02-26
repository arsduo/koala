require 'spec_helper'

describe "Koala::Facebook::GraphAPI" do
  include LiveTestingDataHelper
  
  context "with an access token" do
    before :each do
      @api = Koala::Facebook::GraphAPI.new(@token)
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  context "without an access token" do
    before :each do
      @api = Koala::Facebook::GraphAPI.new
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end