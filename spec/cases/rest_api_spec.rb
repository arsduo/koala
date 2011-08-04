require 'spec_helper'

describe "Koala::Facebook::RestAPI" do
    
  context "with an access token" do
    before :each do
      @api = Koala::Facebook::RestAPI.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
  end
  
end