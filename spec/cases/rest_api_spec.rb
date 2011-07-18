require 'spec_helper'

describe "Koala::Facebook::RestAPI" do
  
  context "without an access token" do
    before :each do
      @api = Koala::Facebook::RestAPI.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"
  end
  
  context "with an access token" do
    before :each do
      @api = Koala::Facebook::RestAPI.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"
  end
  
end