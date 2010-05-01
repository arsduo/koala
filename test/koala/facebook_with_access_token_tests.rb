class FacebookWithAccessTokenTests < Test::Unit::TestCase
  describe "Koala GraphAPI with an access token" do
    before :each do
      token = $testing_data["oauth_token"]
      raise Exception, "Must supply access token to run FacebookWithAccessTokenTests!" unless token
      @graph = Koala::GraphAPI.new(token)
    end
    
    after :each do 
      # clean up any temporary objects
      if @temporary_object_id
        puts "\nCleaning up temporary object #{@temporary_object_id.to_s}"
        @graph.delete_object(@temporary_object_id)
      end
    end

    it "should get public data about a user" do
      result = @graph.get_object("koppel")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should_not be_nil
    end

    it "should get private data about a user" do
      result = @graph.get_object("koppel")
      # updated_time should be a pretty fixed test case
      result["updated_time"].should_not be_nil
    end

    it "should get public data about a Page" do
      result = @graph.get_object("contextoptional")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should
    end
  
    it "should get data about 'me'" do
      result = @graph.get_object("me")
      result["updated_time"].should
    end
  
    it "should be able to get multiple objects" do
      result = @graph.get_objects(["contextoptional", "naitik"])
      result.length.should == 2
    end
  
    it "should be able to access connections from users" do
      result = @graph.get_connections("lukeshepard", "likes")
      result["data"].length.should > 0
    end

    it "should be able to access connections from public Pages" do
      result = @graph.get_connections("contextoptional", "likes")
      result["data"].should be_a(Array)
    end
    
    # PUT
    it "should be able to put an object" do
      result = @graph.put_wall_post("Hello, world, from the test suite!")
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    # DELETE
    it "should not be able to delete posts" do 
      result = @graph.put_wall_post("Hello, world, from the test suite delete method!")
      object_id_to_delete = result["id"]
      delete_result = @graph.delete_object(object_id_to_delete)
      delete_result.should == true
    end

    # these are not strictly necessary as the other put methods resolve to put_object, but are here for completeness
    it "should be able to post to a feed" do
      result = @graph.put_wall_post("Hello, world, from the test suite again!", {:name => "Context Optional", :link => "http://www.contextoptional.com/"})
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    it "should be able to comment on an object" do
      result = @graph.put_wall_post("Hello, world, from the test suite, testing comments!")
      @temporary_object_id = result["id"]
      
      # this will be deleted when the post gets deleted 
      comment_result = @graph.put_comment(@temporary_object_id, "it's my comment!")
      comment_result.should_not be_nil
    end

    it "should be able to like an object" do
      result = @graph.put_wall_post("Hello, world, from the test suite, testing comments!")
      @temporary_object_id = result["id"]
      like_result = @graph.put_like(@temporary_object_id)
    end

    # SEARCH
    it "should be able to search" do
      result = @graph.search("facebook")
      result["data"].should be_an(Array)
    end

    # REQUEST
    # the above tests test this already, but we should do it explicitly
    it "should be able to send get and put requests" do
      # to be written
    end
    
  end # describe

end #class
