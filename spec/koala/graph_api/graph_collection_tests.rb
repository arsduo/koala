# GraphCollection
shared_examples_for "Koala GraphAPI with GraphCollection" do
  describe "when getting a collection" do
    # GraphCollection methods    
    it "should get a GraphCollection when getting connections" do
      @result = @api.get_connections("contextoptional", "photos")
      @result.should be_a(Koala::Facebook::GraphCollection)
    end

    it "should get a GraphCollection when searching" do
      result = @api.search("facebook")
      result.should be_a(Koala::Facebook::GraphCollection)
    end
  
    # GraphCollection attributes
    describe "the GraphCollection" do
      before(:each) do
        @result = @api.get_connections("contextoptional", "photos")
      end
    
      it "should have a read-only paging attribute" do
        lambda { @result.paging }.should_not raise_error
        lambda { @result.paging = "paging" }.should raise_error(NoMethodError)
      end
  
      describe "when getting a whole page" do
        before(:each) do
          @second_page = stub("page of Fb graph results")
          @base = stub("base")
          @args = stub("args")
          @page_of_results = stub("page of results")
        end
    
        it "should return the previous page of results" do
          @result.should_receive(:previous_page_params).and_return([@base, @args])
          @api.should_receive(:graph_call).with(@base, @args).and_return(@second_page)
          Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)
      
          @result.previous_page(@api).should == @page_of_results
        end
    
        it "should return the next page of results" do
          @result.should_receive(:next_page_params).and_return([@base, @args])
          @api.should_receive(:graph_call).with(@base, @args).and_return(@second_page)
          Koala::Facebook::GraphCollection.should_receive(:new).with(@second_page, @api).and_return(@page_of_results)
      
          @result.next_page.should == @page_of_results        
        end
    
        it "should return nil it there are no other pages" do
          %w{next previous}.each do |this|
            @result.should_receive("#{this}_page_params".to_sym).and_return(nil)
            @result.send("#{this}_page", @api).should == nil
          end
        end
      end
  
      describe "when parsing page paramters" do
        before(:each) do
          @graph_collection = Koala::Facebook::GraphCollection.new({"data" => []}, Koala::Facebook::GraphAPI.new)
        end
    
        it "should return the base as the first array entry" do
          base = "url_path"
          @graph_collection.parse_page_url("anything.com/#{base}?anything").first.should == base 
        end
    
        it "should return the arguments as a hash as the last array entry" do
          args_hash = {"one" => "val_one", "two" => "val_two"}
          @graph_collection.parse_page_url("anything.com/anything?#{args_hash.map {|k,v| "#{k}=#{v}" }.join("&")}").last.should == args_hash
        end
      end
    end
  end
end