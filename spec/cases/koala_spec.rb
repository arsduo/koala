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
      mock_service = double("http service")
      mock_service.should_receive(:deprecated_interface)
      Koala.http_service = mock_service
    end

    it "does not set the service if it's deprecated" do
      mock_service = double("http service")
      mock_service.stub(:deprecated_interface)
      Koala.http_service = mock_service
      Koala.http_service.should == @service
    end

    it "sets the service if it's not deprecated" do
      mock_service = double("http service")
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
    it "yields a configurable object" do
      expect {
        Koala.configure {|c| c.foo = "bar"}
      }.not_to raise_exception
    end

    it "caches the config (singleton)" do
      c = Koala.config
      expect(c.object_id).to eq(Koala.config.object_id)
    end
  end

  describe ".config" do
    it "exposes the basic configuration" do
      Koala::HTTPService::DEFAULT_SERVERS.each_pair do |k, v|
        expect(Koala.config.send(k)).to eq(v)
      end
    end

    it "exposes the values configured" do
      Koala.configure do |config|
        config.graph_server = "some-new.graph_server.com"
      end
      Koala.config.graph_server.should == "some-new.graph_server.com"
    end
  end

end
