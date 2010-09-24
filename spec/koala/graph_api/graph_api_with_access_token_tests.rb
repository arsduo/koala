shared_examples_for "Koala GraphAPI with an access token" do
  it "should get public data about a user" do
      result = @api.get_object("koppel")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should_not be_nil
    end

    it "should get private data about a user" do
      result = @api.get_object("koppel")
      # updated_time should be a pretty fixed test case
      result["updated_time"].should_not be_nil
    end

    it "should get public data about a Page" do
      result = @api.get_object("contextoptional")
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should
    end
  
    it "should get data about 'me'" do
      result = @api.get_object("me")
      result["updated_time"].should
    end
  
    it "should be able to get multiple objects" do
      result = @api.get_objects(["contextoptional", "naitik"])
      result.length.should == 2
    end
  
    it "should be able to access a user's picture" do
      @api.get_picture("chris.baclig").should =~ /http\:\/\//
    end
  
    it "should be able to access a user's picture, given a picture type"  do
      @api.get_picture("chris.baclig", {:type => 'large'}).should =~ /^http\:\/\//
    end
  
    it "should be able to access connections from users" do
      result = @api.get_connections("lukeshepard", "likes")
      result.length.should > 0
    end

    it "should be able to access connections from public Pages" do
      result = @api.get_connections("contextoptional", "photos")
      result.should be_a(Array)
    end
    
    # paging
    # see also graph_collection_tests
    it "should make a request for a page when provided a specific set of page params" do
      query = [1, 2]
      @api.should_receive(:graph_call).with(*query)
      @api.get_page(query)
    end
    
    
    # PUT
    it "should be able to write an object to the graph" do
      result = @api.put_wall_post("Hello, world, from the test suite!")
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end

    # DELETE
    it "should be able to delete posts" do 
      result = @api.put_wall_post("Hello, world, from the test suite delete method!")
      object_id_to_delete = result["id"]
      delete_result = @api.delete_object(object_id_to_delete)
      delete_result.should == true
    end

    # additional put tests
    it "should be able to verify messages posted to a wall" do
      message = "the cats are asleep"
      put_result = @api.put_wall_post(message)
      @temporary_object_id = put_result["id"]
      get_result = @api.get_object(@temporary_object_id)
      
      # make sure the message we sent is the message that got posted
      get_result["message"].should == message
    end

    it "should be able to post a message with an attachment to a feed" do
      result = @api.put_wall_post("Hello, world, from the test suite again!", {:name => "Context Optional", :link => "http://www.contextoptional.com/"})
      @temporary_object_id = result["id"]
      @temporary_object_id.should_not be_nil
    end
    
    it "should be able to verify a message with an attachment posted to a feed" do
      attachment = {"name" => "Context Optional", "link" => "http://www.contextoptional.com/"}
      result = @api.put_wall_post("Hello, world, from the test suite again!", attachment)
      @temporary_object_id = result["id"]
      get_result = @api.get_object(@temporary_object_id)

      # make sure the result we fetch includes all the parameters we sent
      it_matches = attachment.inject(true) {|valid, param| valid && (get_result[param[0]] == attachment[param[0]])}
      it_matches.should == true 
    end

    it "should be able to comment on an object" do
      result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
      @temporary_object_id = result["id"]
      
      # this will be deleted when the post gets deleted 
      comment_result = @api.put_comment(@temporary_object_id, "it's my comment!")
      comment_result.should_not be_nil
    end
    
    it "should be able to verify a comment posted about an object" do
      message_text = "Hello, world, from the test suite, testing comments!"
      result = @api.put_wall_post(message_text)
      @temporary_object_id = result["id"]
      
      # this will be deleted when the post gets deleted 
      comment_text = "it's my comment!"
      comment_result = @api.put_comment(@temporary_object_id, comment_text)
      get_result = @api.get_object(comment_result["id"])

      # make sure the text of the comment matches what we sent
      get_result["message"].should == comment_text
    end

    it "should be able to like an object" do
      result = @api.put_wall_post("Hello, world, from the test suite, testing comments!")
      @temporary_object_id = result["id"]
      like_result = @api.put_like(@temporary_object_id)
    end

    # SEARCH
    it "should be able to search" do
      result = @api.search("facebook")
      result.length.should be_an(Integer)
    end

    # API
    # the above tests test this already, but we should consider additional api tests

    it_should_behave_like "Koala GraphAPI with GraphCollection"
end

class FacebookWithAccessTokenTests < Test::Unit::TestCase
  describe "Koala GraphAPI with an access token" do
    it_should_behave_like "live testing examples"
    it_should_behave_like "Koala GraphAPI with an access token"
    
    before :each do
      @api = Koala::Facebook::GraphAPI.new(@token)
    end
  end
end
