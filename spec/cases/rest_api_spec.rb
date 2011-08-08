require 'spec_helper'

describe "Koala::Facebook::RestAPI" do
  describe "class consolidation" do
    before :each do
      Koala::Utils.stub(:deprecate) # avoid actual messages to stderr
    end

    it "still allows you to instantiate a GraphAndRestAPI object" do
      api = Koala::Facebook::RestAPI.new("token").should be_a(Koala::Facebook::RestAPI)
    end

    it "ultimately creates an API object" do
      api = Koala::Facebook::RestAPI.new("token").should be_a(Koala::Facebook::API)
    end

    it "fires a depreciation warning" do
      Koala::Utils.should_receive(:deprecate)
      api = Koala::Facebook::RestAPI.new("token")
    end
  end

  context "without an access token" do
    before :each do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"
  end

  context "with an access token" do
    before :each do
      @api = Koala::Facebook::API.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"
  end

end