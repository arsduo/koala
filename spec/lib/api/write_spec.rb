require "spec_helper"

module Koala
  module Facebook
    describe API do
      before :each do
        @api = Koala::Facebook::API.new(@token)
        @api_without_token = Koala::Facebook::API.new
        # app API
        @app_id = KoalaTest.app_id
        @app_access_token = KoalaTest.app_access_token
        @app_api = Koala::Facebook::API.new(@app_access_token)
      end

      describe "writing to the graph" do
        describe "#put_connections" do
          context "without an access token" do
            it "can't put an object" do
              lambda { @result = @api.put_connections(KoalaTest.user2, "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::AuthenticationError)
              # legacy put_object syntax
              lambda { @result = @api.put_object(KoalaTest.user2, "feed", :message => "Hello, world") }.should raise_error(Koala::Facebook::AuthenticationError)
            end
          end
        end

        describe "#put_wall_post" do
          context "without an access token" do
            # these are not strictly necessary as the other put methods resolve to put_connections,
            # but are here for completeness
            it "can't post to a feed" do
              (lambda do
                attachment = {:name => "OAuth Playground", :link => "http://oauth.twoalex.com/"}
                @result = @api.put_wall_post("Hello, world", attachment, "facebook")
              end).should raise_error(Koala::Facebook::AuthenticationError)
            end
          end

          context "with an access token" do
            it "writes a message to the wall" do
              result = @api.put_wall_post("Hello, world, from the test suite!")
              put_result = @api.put_wall_post(message)
              @temporary_object_id = put_result["id"]
              get_result = @api.get_object(@temporary_object_id)

              # make sure the message we sent is the message that got posted
              get_result["message"].should == message
            end

            it "posts a message with an attachment to a feed" do
              result = @api.put_wall_post("Hello, world, from the test suite again!", {
                :name => "OAuth Playground", 
                :link => "http://oauth.twoalex.com/"
              })
              @temporary_object_id = result["id"]
              @temporary_object_id.should_not be_nil

              # verify it posted
              get_result = @api.get_object(@temporary_object_id)

              # make sure the result we fetch includes all the parameters we sent
              it_matches = attachment.inject(true) {|valid, param| valid && (get_result[param[0]] == attachment[param[0]])}
              it_matches.should == true
            end

            it "can post a message whose attachment has a properties dictionary" do
              url = KoalaTest.oauth_test_data["callback_url"]
              options = {
              "picture" => "#{KoalaTest.oauth_test_data["callback_url"]}/images/logo.png",
              "name" => "It's a big question",
              "type" => "link",
              "link" => KoalaTest.oauth_test_data["callback_url"],
              "properties" => [
                  {"name" => "Link1'", "text" => "Left", "href" => url},
                  {"name" => "other", "text" => "Straight ahead"}
                ]
              }

              result = @api.put_wall_post("body", options)
              @temporary_object_id = result["id"]
              @temporary_object_id.should_not be_nil
            end
          end
        end

        describe "#put_picture" do
          it "can post photos to the user's wall with an open file object" do
            content_type = "image/jpg"
            file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

            result = @api.put_picture(file, content_type)
            @temporary_object_id = result["id"]
            @temporary_object_id.should_not be_nil
          end

          it "can post photos to the user's wall without an open file object" do
            content_type = "image/jpg",
            file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")

            result = @api.put_picture(file_path, content_type)
            @temporary_object_id = result["id"]
            @temporary_object_id.should_not be_nil
          end

          it "can verify a photo posted to a user's wall" do
            content_type = "image/jpg",
            file_path = File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg")

            expected_message = "This is the test message"

            result = @api.put_picture(file_path, content_type, :message => expected_message)
            @temporary_object_id = result["id"]
            @temporary_object_id.should_not be_nil

            get_result = @api.get_object(@temporary_object_id)
            get_result["name"].should == expected_message
          end


          describe "using a URL instead of a file" do
            before :each do
              @url = "http://img.slate.com/images/redesign2008/slate_logo.gif"
            end

            it "can post photo to the user's wall using a URL" do
              result = @api.put_picture(@url)
              @temporary_object_id = result["id"]
              @temporary_object_id.should_not be_nil
            end

            it "can post photo to the user's wall using a URL and an additional param" do
              result = @api.put_picture(@url, :message => "my message")
              @temporary_object_id = result["id"]
              @temporary_object_id.should_not be_nil
            end
          end
        end

        describe "#put_video" do
          before :each do
            @cat_movie = File.join(File.dirname(__FILE__), "..", "fixtures", "cat.m4v")
            @content_type = "video/mpeg4"
          end

          it "sets options[:video] to true" do
            source = stub("UploadIO")
            Koala::UploadableIO.stub(:new).and_return(source)
            source.stub(:requires_base_http_service).and_return(false)
            Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(:video => true)).and_return(Koala::HTTPService::Response.new(200, "[]", {}))
            @api.put_video("foo")
          end

          it "can post videos to the user's wall with an open file object" do
            file = File.open(@cat_movie)

            result = @api.put_video(file, @content_type)
            @temporary_object_id = result["id"]
            @temporary_object_id.should_not be_nil
          end


          it "can post videos to the user's wall without an open file object" do
            result = @api.put_video(@cat_movie, @content_type)
            @temporary_object_id = result["id"]
            @temporary_object_id.should_not be_nil
          end

          # note: Facebook doesn't post videos immediately to the wall, due to processing time
          # during which get_object(video_id) will return false
          # hence we can't do the same verify test we do for photos
        end

        describe "#put_comment" do
          context "without an access token" do
            it "posts a comment to another object" do
              message_text = "Hello, world, from the test suite, testing comments again!"
              result = @api.put_wall_post(message_text)
              @temporary_object_id = result["id"]

              # this will be deleted when the post gets deleted
              comment_text = "it's my comment!"
              comment_result = @api.put_comment(@temporary_object_id, comment_text)
              get_result = @api.get_object(comment_result["id"])

              # make sure the text of the comment matches what we sent
              get_result["message"].should == comment_text
            end
          end

          context "with an access token" do
            it "can't comment on an object" do
              # random public post on the facebook wall
              lambda { @result = @api.put_comment("7204941866_119776748033392", "The hackathon was great!") }.should raise_error(Koala::Facebook::AuthenticationError)
            end
          end
        end

        describe "#put_like" do
          it "likes an object" do
            result = @api.put_wall_post("Hello, world, from the test suite, testing liking!")
            @temporary_object_id = result["id"]
            like_result = @api.put_like(@temporary_object_id)
            like_result.should be_true
          end
          context "without an access token" do
            it "can't like an object" do
              lambda { @api.put_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::AuthenticationError)
            end
          end
        end

        describe "#set_app_restrictions" do
          before :all do
            oauth = Koala::Facebook::OAuth.new(KoalaTest.app_id, KoalaTest.secret)
            app_token = oauth.get_app_access_token
            @app_api = Koala::Facebook::API.new(app_token)
            @restrictions = {"age_distr" => "13+"}
          end

          it "makes a POST to /app_id" do
            @app_api.should_receive(:graph_call).with(KoalaTest.app_id, anything, "post", anything)
            @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
          end

          it "JSON-encodes the restrictions" do
            @app_api.should_receive(:graph_call).with(anything, hash_including(:restrictions => MultiJson.dump(@restrictions)), anything, anything)
            @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions)
          end

          it "includes the other arguments" do
            args = {:a => 2}
            @app_api.should_receive(:graph_call).with(anything, hash_including(args), anything, anything)
            @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions, args)
          end

          it "works" do
            @app_api.set_app_restrictions(KoalaTest.app_id, @restrictions).should be_true
          end
        end
      end
    end
  end
end
