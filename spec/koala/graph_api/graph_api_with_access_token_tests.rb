shared_examples_for "Koala GraphAPI with an access token" do

  it "should get private data about a user" do
    result = @api.get_object("koppel")
    # updated_time should be a pretty fixed test case
    result["updated_time"].should_not be_nil
  end

  it "should get data about 'me'" do
    result = @api.get_object("me")
    result["updated_time"].should
  end

  it "should be able to get multiple objects" do
    result = @api.get_objects(["contextoptional", "naitik"])
    result.length.should == 2
  end
  it "should be able to access connections from users" do
    result = @api.get_connections("lukeshepard", "likes")
    result.length.should > 0
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
  
  it "should be able to delete likes" do
    result = @api.put_wall_post("Hello, world, from the test suite delete method!")
    @temporary_object_id = result["id"]
    @api.put_like(@temporary_object_id)
    delete_like_result = @api.delete_like(@temporary_object_id)
    delete_like_result.should == true
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

  it "should be able to post photos to the user's wall" do
    path_to_picture = File.expand_path(File.dirname(__FILE__) + "/../assets/beach.jpg")
    
    result = @api.put_picture(path_to_picture)
    @temporary_object_id = result["id"] 
    @temporary_object_id.should_not be_nil
  end
    
  it "should be able to verify a photo posted to a user's wall" do
    path_to_picture = File.expand_path(File.dirname(__FILE__) + "/../assets/beach.jpg")
    expected_message = "This is the test message"
    
    result = @api.put_picture(path_to_picture, :message => expected_message)
    @temporary_object_id = result["id"] 
    @temporary_object_id.should_not be_nil
    
    get_result = @api.get_object(@temporary_object_id)
    get_result["name"].should == expected_message
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
    like_result.should be_true
  end
end

class FacebookWithAccessTokenTests < Test::Unit::TestCase
  describe "Koala GraphAPI with an access token" do
    include LiveTestingDataHelper

    before :each do
      @api = Koala::Facebook::GraphAPI.new(@token)
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"

  end
end
