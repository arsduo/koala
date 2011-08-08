require 'spec_helper'

describe "Koala::Facebook::GraphAndRestAPI" do
  describe "class consolidation" do
    before :each do
      Koala::Utils.stub(:deprecate) # avoid actual messages to stderr
    end

    it "still allows you to instantiate a GraphAndRestAPI object" do
      api = Koala::Facebook::GraphAndRestAPI.new("token").should be_a(Koala::Facebook::GraphAndRestAPI)
    end

    it "ultimately creates an API object" do
      api = Koala::Facebook::GraphAndRestAPI.new("token").should be_a(Koala::Facebook::API)
    end

    it "fires a depreciation warning" do
      Koala::Utils.should_receive(:deprecate)
      api = Koala::Facebook::GraphAndRestAPI.new("token")
    end
  end

  describe "with an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  describe "without an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end