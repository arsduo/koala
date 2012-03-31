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
    describe "#parse_page_url" do
      it "should pass the url to the class method" do
        url = stub("url")
        Koala::Facebook::GraphCollection.should_receive(:parse_page_url).with(url)
        @collection.parse_page_url(url)
      end

      it "should return the result of the class method" do
        parsed_content = stub("parsed_content")
        Koala::Facebook::GraphCollection.stub(:parse_page_url).and_return(parsed_content)
        @collection.parse_page_url(stub("url")).should == parsed_content
      end
    end

    describe ".parse_page_url" do
      it "should return the base as the first array entry" do
        base = "url_path"
        Koala::Facebook::GraphCollection.parse_page_url("http://facebook.com/#{base}?anything").first.should == base
      end

      it "should return the arguments as a hash as the last array entry" do
        args_hash = {"one" => "val_one", "two" => "val_two"}
        Koala::Facebook::GraphCollection.parse_page_url("http://facebook.com/anything?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").last.should == args_hash
      end

      it "works with non-.com addresses" do
        base = "url_path"
        args_hash = {"one" => "val_one", "two" => "val_two"}
        Koala::Facebook::GraphCollection.parse_page_url("http://facebook.com/#{base}?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").should == [base, args_hash]
      end
    end
  end

  describe ".evaluate" do
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