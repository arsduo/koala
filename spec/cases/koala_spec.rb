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

  describe ".configure" do
    it "should yield a config object" do
      config = nil
      Koala.configure {|c| config = c}

      config.class.should == Koala::Config
    end

    it "should cache the config (singleton)" do
      configs = []
      2.times { Koala.configure {|c| configs << c } }

      configs.should have(2).items
      configs.map(&:object_id).uniq.should == [Koala.config.object_id]
    end
  end

  describe ".config" do
    before do
      Koala.configure do |config|
        config.graph_server = "some-new.graph_server.com"
      end
    end

    it "should expose the values configured" do
      Koala.config.graph_server.should == "some-new.graph_server.com"
    end
  end

end
