class ApiBaseTests < Test::Unit::TestCase
  describe "Koala API base class" do
    before(:each) do
      @service = Koala::Facebook::API.new  
    end
    
    it "should not include an access token if none was given" do
      Koala.should_receive(:make_request).with(
        anything,
        hash_not_including('access_token' => 1),
        anything,
        anything
      ).and_return(Koala::Response.new(200, "", ""))
      
      @service.api('anything')
    end
    
    it "should include an access token if given" do
      token = 'adfadf'
      service = Koala::Facebook::API.new token
      
      Koala.should_receive(:make_request).with(
        anything,
        hash_including('access_token' => token),
        anything,
        anything
      ).and_return(Koala::Response.new(200, "", ""))
      
      service.api('anything')
    end
    
    it "should properly handle the http_component parameter"
    
    it "should execute a block to test for errors if passed one"
    
    it "should handle rogue true/false as responses" do
      Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'true', {}))
      @service.api('anything').should be_true
      
      Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'false', {}))
      @service.api('anything').should be_false
    end
  end
end