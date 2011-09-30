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
end