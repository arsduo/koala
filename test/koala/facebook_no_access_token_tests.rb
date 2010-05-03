class FacebookNoAccessTokenTests < Test::Unit::TestCase
  
  describe "Koala GraphAPI without an access token" do
    before :each do
      @graph = Koala::Facebook::GraphAPI.new
    end
  
    it "should get public data about a user" do
      result = @graph.get_object("koppel")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should
    end

    it "should not get private data about a user" do
      result = @graph.get_object("koppel")
      # updated_time should be a pretty fixed test case
      result["updated_time"].should be_nil
    end

  
    it "should get public data about a Page" do
      result = @graph.get_object("contextoptional")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should
    end
  
    it "should not be able to get data about 'me'" do
      begin
        @graph.get_object("me")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end
  
    it "should be able to get multiple objects" do
      results = @graph.get_objects(["contextoptional", "naitik"])
      results.length.should == 2
    end
  
    it "shouldn't be able to access connections from users" do
      begin
        @graph.get_connections("lukeshepard", "likes")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end

    it "should be able to access connections from public Pages" do
      result = @graph.get_connections("contextoptional", "likes")
      result["data"].should be_a(Array)
    end
  
    it "should not be able to put an object" do
      begin
        @result = @graph.put_object("lukeshepard", "feed", :message => "Hello, world")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end

    # these are not strictly necessary as the other put methods resolve to put_object, but are here for completeness
    it "should not be able to post to a feed" do
      begin
        @result = @graph.put_wall_post("Hello, world", {:name => "Context Optional", :link => "http://www.contextoptional.com/"}, "contextoptional")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end

    it "should not be able to comment on an object" do
      begin
        # random public post on the ContextOptional wall
        @result = @graph.put_comment("7204941866_119776748033392", "The hackathon was great!")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end

    it "should not be able to like an object" do
      begin
        @result = @graph.put_like("7204941866_119776748033392")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end


    # DELETE
    it "should not be able to delete posts" do 
      begin
        # test post on the Ruby SDK Test application
        @result = @graph.delete_object("115349521819193_113815981982767")
      rescue Koala::Facebook::GraphAPIError => @right_err
      rescue Exception => wrong_err
      end
      @right_err.should_not be_nil
    end

    # SEARCH
    it "should be able to search" do
      result = @graph.search("facebook")
      result["data"].should be_an(Array)
    end

    # API
    # the above tests test this already, but we should consider additional api tests
    
  end # describe

end #class
  