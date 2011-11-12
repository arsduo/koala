require 'spec_helper'

describe Koala do

  
  it "has an http_service accessor" do
    Koala.should respond_to(:http_service)
    Koala.should respond_to(:http_service=)
  end
  
  describe "constants" do
    it "has a version" do
      Koala.const_defined?("VERSION").should be_true
    end

    describe Koala::Facebook do      
      it "defines GRAPH_SERVER" do
        Koala::Facebook::GRAPH_SERVER.should == "graph.facebook.com"
      end

      it "defines REST_SERVER" do
        Koala::Facebook::REST_SERVER.should == "api.facebook.com"
      end
      
      it "defines DIALOG_HOST" do
        Koala::Facebook::DIALOG_HOST.should == "www.facebook.com"
      end
    end
  end
  
  context "for deprecated services" do
    before :each do
      @service = Koala.http_service
    end
    
    after :each do
      Koala.http_service = @service
    end

    it "invokes deprecated_interface if present" do
      mock_service = stub("http service")
      mock_service.should_receive(:deprecated_interface)
      Koala.http_service = mock_service
    end
    
    it "does not set the service if it's deprecated" do
      mock_service = stub("http service")
      mock_service.stub(:deprecated_interface)
      Koala.http_service = mock_service
      Koala.http_service.should == @service
    end

    it "sets the service if it's not deprecated" do
      mock_service = stub("http service")
      Koala.http_service = mock_service
      Koala.http_service.should == mock_service
    end
  end

  describe "make_request" do
    it "passes all its arguments to the http_service" do
      path = "foo"
      args = {:a => 2}
      verb = "get"
      options = {:c => :d}
      
      Koala.http_service.should_receive(:make_request).with(path, args, verb, options)
      Koala.make_request(path, args, verb, options)
    end
  end

end