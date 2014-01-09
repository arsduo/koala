require 'spec_helper'

# Support for legacy / deprecated interfaces
describe "legacy APIs" do

  it "deprecates the REST API" do
    api = Koala::Facebook::API.new
    allow(api).to receive(:api)
    expect(Koala::Utils).to receive(:deprecate)
    api.rest_call("stuff")
  end

  describe Koala::Facebook::GraphAPI do
    describe "class consolidation" do
      before :each do
        allow(Koala::Utils).to receive(:deprecate) # avoid actual messages to stderr
      end

      it "still allows you to instantiate a GraphAndRestAPI object" do
        api = expect(Koala::Facebook::GraphAPI.new("token")).to be_a(Koala::Facebook::GraphAPI)
      end

      it "ultimately creates an API object" do
        api = expect(Koala::Facebook::GraphAPI.new("token")).to be_a(Koala::Facebook::API)
      end

      it "fires a depreciation warning" do
        expect(Koala::Utils).to receive(:deprecate)
        api = Koala::Facebook::GraphAPI.new("token")
      end
    end
  end

  describe Koala::Facebook::RestAPI do
    describe "class consolidation" do
      before :each do
        allow(Koala::Utils).to receive(:deprecate) # avoid actual messages to stderr
      end

      it "still allows you to instantiate a GraphAndRestAPI object" do
        api = expect(Koala::Facebook::RestAPI.new("token")).to be_a(Koala::Facebook::RestAPI)
      end

      it "ultimately creates an API object" do
        api = expect(Koala::Facebook::RestAPI.new("token")).to be_a(Koala::Facebook::API)
      end

      it "fires a depreciation warning" do
        expect(Koala::Utils).to receive(:deprecate)
        api = Koala::Facebook::RestAPI.new("token")
      end
    end
  end

  describe Koala::Facebook::GraphAndRestAPI do
    describe "class consolidation" do
      before :each do
        allow(Koala::Utils).to receive(:deprecate) # avoid actual messages to stderr
      end

      it "still allows you to instantiate a GraphAndRestAPI object" do
        api = expect(Koala::Facebook::GraphAndRestAPI.new("token")).to be_a(Koala::Facebook::GraphAndRestAPI)
      end

      it "ultimately creates an API object" do
        api = expect(Koala::Facebook::GraphAndRestAPI.new("token")).to be_a(Koala::Facebook::API)
      end

      it "fires a depreciation warning" do
        expect(Koala::Utils).to receive(:deprecate)
        api = Koala::Facebook::GraphAndRestAPI.new("token")
      end
    end
  end

  {:typhoeus => Koala::TyphoeusService, :net_http => Koala::NetHTTPService}.each_pair do |adapter, module_class|
    describe module_class.to_s do
      it "responds to deprecated_interface" do
        expect(module_class).to respond_to(:deprecated_interface)
      end

      it "issues a deprecation warning" do
        expect(Koala::Utils).to receive(:deprecate)
        module_class.deprecated_interface
      end

      it "sets the default adapter to #{adapter}" do
        module_class.deprecated_interface
        expect(Faraday.default_adapter).to eq(adapter)
      end
    end
  end

  describe "moved classes" do
    it "allows you to access Koala::HTTPService::MultipartRequest through the Koala module" do
      expect(Koala::MultipartRequest).to eq(Koala::HTTPService::MultipartRequest)
    end
    
    it "allows you to access Koala::Response through the Koala module" do
      expect(Koala::Response).to eq(Koala::HTTPService::Response)
    end
    
    it "allows you to access Koala::Response through the Koala module" do
      expect(Koala::UploadableIO).to eq(Koala::HTTPService::UploadableIO)
    end
    
    it "allows you to access Koala::Facebook::GraphBatchAPI::BatchOperation through the Koala::Facebook module" do
      expect(Koala::Facebook::BatchOperation).to eq(Koala::Facebook::GraphBatchAPI::BatchOperation)
    end 
    
    it "allows you to access Koala::Facebook::API::GraphCollection through the Koala::Facebook module" do
      expect(Koala::Facebook::GraphCollection).to eq(Koala::Facebook::API::GraphCollection)
    end   
  end
end