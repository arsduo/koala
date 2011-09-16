require 'spec_helper'

describe Koala::Facebook::GraphCollection do
  before(:each) do
    @result = {
      "data" => [1, 2, :three],
      "paging" => {:paging => true}
    }
    @api = Koala::Facebook::API.new("123")
    @collection = Koala::Facebook::GraphCollection.new(@result, @api)
  end

  it "subclasses Array" do
    Koala::Facebook::GraphCollection.ancestors.should include(Array)
  end
  
  it "creates an array-like object" do
    Koala::Facebook::GraphCollection.new(@result, @api).should be_an(Array)
  end
  
  it "contains the result data" do
    @result["data"].each_with_index {|r, i| @collection[i].should == r}
  end

  it "has a read-only paging attribute" do
    @collection.methods.map(&:to_sym).should include(:paging)
    @collection.methods.map(&:to_sym).should_not include(:paging=)
  end
  
  it "sets paging to results['paging']" do
    @collection.paging.should == @result["paging"]
  end
  
  it "sets raw_response to the original results" do
    @collection.raw_response.should == @result
  end
  
  it "sets the API to the provided API" do
    @collection.api.should == @api
  end
    
  describe "when getting a whole page" do
    before(:each) do
      @second_page = {
        "data" => [:second, :page, :data],
        "paging" => {}
      }
      @base = stub("base")
      @args = stub("args")
      @page_of_results = stub("page of results")
    end

    it "should return the previous page of results" do
      @collection.should_receive(:previous_page_params).and_return([@base, @args])
      @api.should_receive(:api).with(@base, @args, anything, anything).and_return(@second_page)
      Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)
      @collection.previous_page.should == @page_of_results
    end

    it "should return the next page of results" do
      @collection.should_receive(:next_page_params).and_return([@base, @args])
      @api.should_receive(:api).with(@base, @args, anything, anything).and_return(@second_page)
      Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)

      @collection.next_page.should == @page_of_results
    end

    it "should return nil it there are no other pages" do
      %w{next previous}.each do |this|
        @collection.should_receive("#{this}_page_params".to_sym).and_return(nil)
        @collection.send("#{this}_page").should == nil
      end
    end
  end

  describe "when parsing page paramters" do
    it "should return the base as the first array entry" do
      base = "url_path"
      @collection.parse_page_url("anything.com/#{base}?anything").first.should == base
    end

    it "should return the arguments as a hash as the last array entry" do
      args_hash = {"one" => "val_one", "two" => "val_two"}
      @collection.parse_page_url("anything.com/anything?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").last.should == args_hash
    end
  end

  describe "#evaluate" do
    it "returns the original result if it's provided a non-hash result" do
      result = []
      Koala::Facebook::GraphCollection.evaluate(result, @api).should == result
    end
    
    it "returns the original result if it's provided a nil result" do
      result = nil
      Koala::Facebook::GraphCollection.evaluate(result, @api).should == result
    end
    
    it "returns the original result if the result doesn't have a data key" do
      result = {"paging" => {}}
      Koala::Facebook::GraphCollection.evaluate(result, @api).should == result
    end
    
    it "returns the original result if the result's data key isn't an array" do
      result = {"data" => {}, "paging" => {}}
      Koala::Facebook::GraphCollection.evaluate(result, @api).should == result
    end
        
    it "returns a new GraphCollection of the result if it has an array data key and a paging key" do
      result = {"data" => [], "paging" => {}}
      expected = :foo
      Koala::Facebook::GraphCollection.should_receive(:new).with(result, @api).and_return(expected)
      Koala::Facebook::GraphCollection.evaluate(result, @api).should == expected
    end
  end
end