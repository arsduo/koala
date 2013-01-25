require 'spec_helper'

describe Koala::HTTPService::MultipartRequest do
  it "is a subclass of Faraday::Request::Multipart" do
    Koala::HTTPService::MultipartRequest.superclass.should == Faraday::Request::Multipart
  end
  
  it "defines mime_type as multipart/form-data" do
    Koala::HTTPService::MultipartRequest.mime_type.should == 'multipart/form-data'
  end
  
  describe "#process_request?" do
    before :each do
      @env = {}
      @multipart = Koala::HTTPService::MultipartRequest.new
      @multipart.stub(:request_type).and_return("")
    end
    
    # no way to test the call to super, unfortunately
    it "returns true if env[:body] is a hash with at least one hash in its values" do
      @env[:body] = {:a => {:c => 2}}
      @multipart.process_request?(@env).should be_true
    end

    it "returns true if env[:body] is a hash with at least one array in its values" do
      @env[:body] = {:a => [:c, 2]}
      @multipart.process_request?(@env).should be_true
    end

    it "returns true if env[:body] is a hash with mixed objects in its values" do
      @env[:body] = {:a => [:c, 2], :b => {:e => :f}}
      @multipart.process_request?(@env).should be_true
    end

    it "returns false if env[:body] is a string" do
      @env[:body] = "my body"
      @multipart.process_request?(@env).should be_false
    end

    it "returns false if env[:body] is a hash without an array or hash value" do
      @env[:body] = {:a => 3}
      @multipart.process_request?(@env).should be_false
    end    
  end
  
  describe "#process_params" do
    before :each do
      @parent = Faraday::Request::Multipart.new
      @multipart = Koala::HTTPService::MultipartRequest.new 
      @block = lambda {|k, v| "#{k}=#{v}"}     
    end
    
    it "is identical to the parent for requests without a prefix" do
      hash = {:a => 2, :c => "3"}
      @multipart.process_params(hash, &@block).should == @parent.process_params(hash, &@block)
    end
    
    it "replaces encodes [ and ] if the request has a prefix" do
      hash = {:a => 2, :c => "3"}
      prefix = "foo"
      # process_params returns an array
      @multipart.process_params(hash, prefix, &@block).join("&").should == @parent.process_params(hash, prefix, &@block).join("&").gsub(/\[/, "%5B").gsub(/\]/, "%5D")
    end
  end
  
end