class TestUsersTests < Test::Unit::TestCase
  include Koala

  describe "Koala TestUsers with access token" do
    include LiveTestingDataHelper

    before :all do
      # get oauth data
      @oauth_data = $testing_data["oauth_test_data"]
      @app_id = @oauth_data["app_id"]
      @secret = @oauth_data["secret"]
      @app_access_token = @oauth_data["app_access_token"]

      # check OAuth data
      unless @app_id && @secret && @app_access_token
        raise Exception, "Must supply OAuth app id, secret, app_access_token, and callback to run live subscription tests!"
      end

      @is_mock = defined?(Koala::IS_MOCK) && Koala::IS_MOCK
    end

    describe "when initializing" do
      # basic initialization
      it "should initialize properly with an app_id and an app_access_token" do
        test_users = Facebook::TestUsers.new(:app_id => @app_id, :app_access_token => @app_access_token)
        test_users.should be_a(Facebook::TestUsers)
      end

      # init with secret / fetching the token
      it "should initialize properly with an app_id and a secret" do
        test_users = Facebook::TestUsers.new(:app_id => @app_id, :secret => @secret)
        test_users.should be_a(Facebook::TestUsers)
      end

      it "should use the OAuth class to fetch a token when provided an app_id and a secret" do
        oauth = Facebook::OAuth.new(@app_id, @secret)
        token = oauth.get_app_access_token
        oauth.should_receive(:get_app_access_token).and_return(token)
        Facebook::OAuth.should_receive(:new).with(@app_id, @secret).and_return(oauth)
        test_users = Facebook::TestUsers.new(:app_id => @app_id, :secret => @secret)
      end
    end

    describe "when used without network" do
      before :each do
        @test_users = Facebook::TestUsers.new({:app_access_token => @app_access_token, :app_id => @app_id})
      end

      # TEST USER MANAGEMENT
      it "should create a test user when not given installed" do
        result = @test_users.create(false)
        @temporary_object_id = result["id"]
        result.should be_a(Hash)
        (result["id"] && result["access_token"] && result["login_url"]).should
      end

      it "should create a test user when not given installed, ignoring permissions" do
        result = @test_users.create(false, "read_stream")
        @temporary_object_id = result["id"]
        result.should be_a(Hash)
        (result["id"] && result["access_token"] && result["login_url"]).should
      end

      it "should accept permissions as a string" do
        @test_users.graph_api.should_receive(:graph_call).with(anything, hash_including("permissions" => "read_stream,publish_stream"), anything)
        result = @test_users.create(true, "read_stream,publish_stream")
      end

      it "should accept permissions as an array" do
        @test_users.graph_api.should_receive(:graph_call).with(anything, hash_including("permissions" => "read_stream,publish_stream"), anything)
        result = @test_users.create(true, ["read_stream", "publish_stream"])
      end

      it "should create a test user when given installed and a permission" do
        result = @test_users.create(true, "read_stream")
        @temporary_object_id = result["id"]
        result.should be_a(Hash)
        (result["id"] && result["access_token"] && result["login_url"]).should
      end

      describe "with a user to delete" do
        before :each do
          @user1 = @test_users.create(true, "read_stream")
          @user2 = @test_users.create(true, "read_stream,user_interests")
        end

        after :each do
          print "\nCleaning up test users..."
          @test_users.delete(@user1) if @user1
          @test_users.delete(@user2) if @user2
          puts "done."
        end

        it "should delete a user by id" do
          @test_users.delete(@user1['id']).should be_true
          @user1 = nil
        end

        it "should delete a user by hash" do
          @test_users.delete(@user2).should be_true
          @user2 = nil
        end

        it "should not delete users when provided a false ID" do
          lambda { @test_users.delete("#{@user1['id']}1") }.should raise_exception(Koala::Facebook::APIError)
        end
      end

      describe "with delete_all" do
        it "should delete all users found by the list commnand" do
          array = [1, 2, 3]
          @test_users.should_receive(:list).and_return(array)
          array.each {|i| @test_users.should_receive(:delete).with(i) }
          @test_users.delete_all
        end
      end

      describe "with existing users" do
        before :each do
          @user1 = @test_users.create(true, "read_stream")
          @user2 = @test_users.create(true, "read_stream,user_interests")
        end

        after :each do
          @test_users.delete(@user1)
          @test_users.delete(@user2)
        end

        it "should list test users" do
          result = @test_users.list
          result.should be_an(Array)
          first_user, second_user = result[0], result[1]
          (first_user["id"] && first_user["access_token"] && first_user["login_url"]).should
          (second_user["id"] && second_user["access_token"] && second_user["login_url"]).should
        end
        
        it "should make two users into friends with string hashes" do
          result = @test_users.befriend(@user1, @user2)
          result.should be_true
        end
        
        it "should make two users into friends with symbol hashes" do
          new_user_1 = {}
          @user1.each_pair {|k, v| new_user_1[k.to_sym] = v}
          new_user_2 = {}
          @user2.each_pair {|k, v| new_user_2[k.to_sym] = v}
          
          result = @test_users.befriend(new_user_1, new_user_2)
          result.should be_true
        end        
        
        it "should not accept user IDs anymore" do
          lambda { @test_users.befriend(@user1["id"], @user2["id"]) }.should raise_exception(ArgumentError)
        end
      end # with existing users

    end # when used without network

    describe "when creating a network of friends" do
      before :each do
        @test_users = Facebook::TestUsers.new({:app_access_token => @app_access_token, :app_id => @app_id})
        @network = []

        if @is_mock
          id_counter = 999999900
          @test_users.stub!(:create).and_return do
            id_counter += 1
            {"id" => id_counter, "access_token" => @token, "login_url" => "https://www.facebook.com/platform/test_account.."}
          end
          @test_users.stub!(:befriend).and_return(true)
          @test_users.stub!(:delete).and_return(true)
        end
      end

      describe "tests that create users" do
        before :each do
          print "\nCleaning up test user network..."
          test_users = Facebook::TestUsers.new({:app_access_token => @app_access_token, :app_id => @app_id})
          test_users.delete_all
          puts "done!"
        end

        after :each do
          print "\nCleaning up test user network..."
          test_users = Facebook::TestUsers.new({:app_access_token => @app_access_token, :app_id => @app_id})
          test_users.delete_all
          puts "done!"
        end

        it "should create a 5 person network" do
          size = 5
          @network = @test_users.create_network(size)
          @network.should be_a(Array)
          @network.size.should == size
        end
      end

      it "should limit to a 50 person network" do
        @test_users.should_receive(:create).exactly(50).times
        @test_users.stub!(:befriend)
        @network = @test_users.create_network(51)
      end

      it "should pass on the installed and permissions parameters to create" do
        perms = ["read_stream", "offline_access"]
        installed = false
        count = 25
        @test_users.should_receive(:create).exactly(count).times.with(installed, perms)
        @test_users.stub!(:befriend)
        @network = @test_users.create_network(count, installed, perms)
      end

    end # when creating network

  end  # describe Koala TestUsers
end # class