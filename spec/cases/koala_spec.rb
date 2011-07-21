require 'spec_helper'

describe "Koala" do
  it "has an http_service accessor" do
    Koala.respond_to?(:http_service)
  end

  it "should let an http service be set" do
    current_service = Koala.http_service
    Koala.http_service = Koala::MockHTTPService
    Koala.http_service.should == Koala::MockHTTPService
    # reset the service back to the original one (important for live tests)
    Koala.http_service = current_service
  end

  describe ".make_request" do
    before :each do
      @old_service = Koala.http_service
      Koala.http_service = Koala::MockHTTPService
    end
    
    after :each do
      Koala.http_service = @old_service
    end

    it "should allow the caller to override the http_service" do
      http_service = stub
      http_service.should_receive(:make_request)
      
      Koala.make_request(anything, anything, anything, :http_service => http_service)
    end

  end
end