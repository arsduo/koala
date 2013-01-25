require 'spec_helper'

# Support for legacy / deprecated interfaces
describe "legacy APIs" do

  it "deprecates the REST API" do
    api = Koala::Facebook::API.new
    api.stub(:api)
    Koala::Utils.should_receive(:deprecate)
    api.rest_call("stuff")
  end

  describe Koala::Facebook::GraphAPI do
    describe "class consolidation" do
      before :each do
        Koala::Utils.stub(:deprecate) # avoid actual messages to stderr
      end

      it "still allows you to instantiate a GraphAndRestAPI object" do
        api = Koala::Facebook::GraphAPI.new("token").should be_a(Koala::Facebook::GraphAPI)
      end

      it "ultimately creates an API object" do
        api = Koala::Facebook::GraphAPI.new("token").should be_a(Koala::Facebook::API)
      end

      it "fires a depreciation warning" do
        Koala::Utils.should_receive(:deprecate)
        api = Koala::Facebook::GraphAPI.new("token")
      end
    end
  end

  describe Koala::Facebook::RestAPI do
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

  describe Koala::Facebook::GraphAndRestAPI do
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

  {:typhoeus => Koala::TyphoeusService, :net_http => Koala::NetHTTPService}.each_pair do |adapter, module_class|
    describe module_class.to_s do
      it "responds to deprecated_interface" do
        module_class.should respond_to(:deprecated_interface)
      end

      it "issues a deprecation warning" do
        Koala::Utils.should_receive(:deprecate)
        module_class.deprecated_interface
      end

      it "sets the default adapter to #{adapter}" do
        module_class.deprecated_interface
        Faraday.default_adapter.should == adapter
      end
    end
  end

  describe "moved classes" do
    it "allows you to access Koala::HTTPService::MultipartRequest through the Koala module" do
      Koala::MultipartRequest.should == Koala::HTTPService::MultipartRequest
    end
    
    it "allows you to access Koala::Response through the Koala module" do
      Koala::Response.should == Koala::HTTPService::Response
    end
    
    it "allows you to access Koala::Response through the Koala module" do
      Koala::UploadableIO.should == Koala::HTTPService::UploadableIO
    end
    
    it "allows you to access Koala::Facebook::GraphBatchAPI::BatchOperation through the Koala::Facebook module" do
      Koala::Facebook::BatchOperation.should == Koala::Facebook::GraphBatchAPI::BatchOperation
    end 
    
    it "allows you to access Koala::Facebook::API::GraphCollection through the Koala::Facebook module" do
      Koala::Facebook::GraphCollection.should == Koala::Facebook::API::GraphCollection
    end   
  end
end