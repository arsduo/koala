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
end