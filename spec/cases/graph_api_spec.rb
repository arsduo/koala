require 'spec_helper'

describe "Koala::Facebook::GraphAPI" do  
  describe "class consolidation" do
    before :each do
      Koala::Utils.stub(:deprecate) # avoid actual messages to stderr
    end
    
    it "still allows you to instantiate a GraphAndRestAPI object" do
      api = Koala::Facebook::GraphAPI.new("token").should be_a(Koala::Facebook::GraphAPI)
    end

    it "ultimately creates an API object" do
      api = Koala::Facebook::GraphAPI.new("token").should be_a(Koala::Facebook::API)
    end
        
    it "fires a depreciation warning" do
      Koala::Utils.should_receive(:deprecate)
      api = Koala::Facebook::GraphAPI.new("token")
    end
  end
  
  context "with an access token" do
    before :each do
      @api = Koala::Facebook::API.new(@token)
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  context "without an access token" do
    before :each do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end