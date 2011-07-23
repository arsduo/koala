require 'spec_helper'

describe "Koala" do
  it "has an http_service accessor" do
    Koala.respond_to?(:http_service)
  end

  it "should let an http service be set" do
    current_service = Koala.http_service
    service = stub("http_service")
    Koala.http_service = service
    Koala.http_service.should == service
    # reset the service back to the original one (important for live tests)
    Koala.http_service = current_service
  end
end