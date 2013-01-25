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

      describe "reading information from the graph" do
        describe "#get_object" do
          context "without an access token" do
            it "gets public data about a user" do
              result = @api_without_token.get_object(KoalaTest.user1)
              # the results should have an ID and a name, among other things
              (result["id"] && result["name"]).should_not be_nil
            end

            it "gets public data about a Page" do
              result = @api_without_token.get_object(KoalaTest.page)
              # the results should have an ID and a name, among other things
              (result["id"] && result["name"]).should
            end

            it "can't get private data about a user" do
              result = @api_without_token.get_object(KoalaTest.user1)
              # updated_time should be a pretty fixed test case
              result["updated_time"].should be_nil
            end

            it "can't get data about 'me'" do
              lambda { @api_without_token.get_object("me") }.should raise_error(Koala::Facebook::ClientError)
            end
          end

          context "with an access token" do
            it "gets private data about a user" do
              result = @api.get_object(KoalaTest.user1)
              # updated_time should be a pretty fixed test case
              result["updated_time"].should_not be_nil
            end

            it "gets data about 'me'" do
              result = @api.get_object("me")
              result["updated_time"].should
            end
          end
        end

        describe "#get_objects" do
          it "returns [] from get_objects if passed an empty array" do
            results = @api.get_objects([])
            results.should == []
          end

          it "gets multiple objects" do
            results = @api.get_objects([KoalaTest.page, KoalaTest.user1])
            results.should have(2).items
          end

          it "gets multiple objects if they're a string" do
            results = @api.get_objects("facebook,#{KoalaTest.user1}")
            results.should have(2).items
          end
        end

        describe "#get_picture" do
          it "can access a user's picture" do
            @api.get_picture(KoalaTest.user2).should =~ /http[s]*\:\/\//
          end

          it "can access a user's picture, given a picture type"  do
            @api.get_picture(KoalaTest.user2, {:type => 'large'}).should =~ /^http[s]*\:\/\//
          end

          it "works even if Facebook returns nil" do
            @api.stub(:graph_call).and_return(nil)
            @api.get_picture(KoalaTest.user2, {:type => 'large'}).should be_nil
          end
        end

        describe "#get_connections" do
          it "gets a GraphCollection when getting connections" do
            @result = @api.get_connections(KoalaTest.page, "photos")
            @result.should be_a(Koala::Facebook::GraphCollection)
          end

          it "returns nil if the get_collections call fails with nil" do
            # this happens sometimes
            @api.should_receive(:graph_call).and_return(nil)
            @api.get_connections(KoalaTest.page, "photos").should be_nil
          end

          context "without an access token" do
            it "can access connections from public Pages" do
              result = @api_without_token.get_connections(KoalaTest.page, "photos")
              result.should be_a(Array)
            end

            it "can't access connections from users" do
              lambda { @api_without_token.get_connections(KoalaTest.user2, "friends") }.should raise_error(Koala::Facebook::ClientError)
            end
          end

          context "with an access token" do
            it "can access connections from users" do
              result = @api.get_connections(KoalaTest.user2, "friends")
              result.length.should > 0
            end
          end
        end

        describe "#get_comments_for_urls" do
          it "can access comments for a URL" do
            result = @api.get_comments_for_urls(["http://developers.facebook.com/blog/post/472"])
            (result["http://developers.facebook.com/blog/post/472"]).should
          end

          it "can access comments for 2 URLs" do
            result = @api.get_comments_for_urls(["http://developers.facebook.com/blog/post/490", "http://developers.facebook.com/blog/post/472"])
            (result["http://developers.facebook.com/blog/post/490"] && result["http://developers.facebook.com/blog/post/472"]).should
          end
        end

        describe "#get_page_access_token" do
          it "gets the page object with the access_token field" do
            # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
            @api.should_receive(:api).with("my_page", hash_including({:fields => "access_token"}), "get", anything)
            @api.get_page_access_token("my_page")
          end

          it "merges in any other arguments" do
            # we can't test this live since test users (or random real users) can't be guaranteed to have pages to manage
            args = {:a => 3}
            @api.should_receive(:api).with("my_page", hash_including(args), "get", anything)
            @api.get_page_access_token("my_page", args)
          end
        end

        describe "#debug_token" do
          it "can get information about an access token" do
            result = @api.debug_token(KoalaTest.app_access_token)
            result.should be_kind_of(Hash)
            result["data"].should be_kind_of(Hash)
            result["data"]["app_id"].to_s.should == KoalaTest.app_id.to_s
            result["data"]["application"].should_not be_nil
          end
        end

        describe "FQL" do
          describe "#fql_query" do
            it "makes a request to /fql" do
              @api.should_receive(:get_object).with("fql", anything, anything)
              @api.fql_query stub('query string')
            end

            it "passes a query argument" do
              query = stub('query string')
              @api.should_receive(:get_object).with(anything, hash_including(:q => query), anything)
              @api.fql_query(query)
            end

            it "passes on any other arguments provided" do
              args = {:a => 2}
              @api.should_receive(:get_object).with(anything, hash_including(args), anything)
              @api.fql_query("a query", args)
            end

            context "without an access token" do
              it "can access public information via FQL" do
                result = @api_without_token.fql_query("select uid, first_name from user where uid = #{KoalaTest.user2_id}")
                result.size.should == 1
                result.first['first_name'].should == KoalaTest.user2_name
                result.first['uid'].should == KoalaTest.user2_id.to_i
              end

              it "can't access protected information via FQL" do
                lambda { @api_without_token.fql_query("select read_stream from permissions where uid = #{KoalaTest.user2_id}") }.should raise_error(Koala::Facebook::APIError)
              end
            end

            context "with an access token" do
              it "can access protected information via FQL" do
                # Tests agains the permissions fql table

                # get the current user's ID
                # we're sneakily using the Graph API, which should be okay since it has its own tests
                g = Koala::Facebook::API.new(@token)
                id = g.get_object("me", :fields => "id")["id"]

                # now send a query about your permissions
                result = @api.fql_query("select read_stream from permissions where uid = #{id}")

                result.size.should == 1
                # we've verified that you have read_stream permissions, so we can test against that
                result.first["read_stream"].should == 1
              end
            end
          end

          describe "#fql_multiquery" do
            it "makes a request to /fql" do
              @api.should_receive(:get_object).with("fql", anything, anything)
              @api.fql_multiquery 'query string'
            end

            it "passes a queries argument" do
              queries = stub('query string')
              queries_json = "some JSON"
              MultiJson.stub(:dump).with(queries).and_return(queries_json)

              @api.should_receive(:get_object).with(anything, hash_including(:q => queries_json), anything)
              @api.fql_multiquery(queries)
            end

            it "simplifies the response format" do
              raw_results = [
                {"name" => "query1", "fql_result_set" => [1, 2, 3]},
                {"name" => "query2", "fql_result_set" => [:a, :b, :c]}
              ]
              expected_results = {
                "query1" => [1, 2, 3],
                "query2" => [:a, :b, :c]
              }

              @api.stub(:get_object).and_return(raw_results)
              results = @api.fql_multiquery({:query => true})
              results.should == expected_results
            end

            it "passes on any other arguments provided" do
              args = {:a => 2}
              @api.should_receive(:get_object).with(anything, hash_including(args), anything)
              @api.fql_multiquery("a query", args)
            end

            context "without an access token" do
              it "can access public information via FQL.multiquery" do
                result = @api_without_token.fql_multiquery(
                  :query1 => "select uid, first_name from user where uid = #{KoalaTest.user2_id}",
                  :query2 => "select uid, first_name from user where uid = #{KoalaTest.user1_id}"
                )
                result.size.should == 2
                # this should check for first_name, but there's an FB bug currently
                result["query1"].first['uid'].should == KoalaTest.user2_id.to_i
                # result["query1"].first['first_name'].should == KoalaTest.user2_name
                result["query2"].first['first_name'].should == KoalaTest.user1_name
              end

              it "can't access protected information via FQL.multiquery" do
                lambda {
                  @api_without_token.fql_multiquery(
                    :query1 => "select post_id from stream where source_id = me()",
                    :query2 => "select fromid from comment where post_id in (select post_id from #query1)",
                    :query3 => "select uid, name from user where uid in (select fromid from #query2)"
                  )
                }.should raise_error(Koala::Facebook::APIError)
              end
            end

            context "with an access token" do
              it "can access protected information via FQL.multiquery" do
                result = @api.fql_multiquery(
                  :query1 => "select post_id from stream where source_id = me()",
                  :query2 => "select fromid from comment where post_id in (select post_id from #query1)",
                  :query3 => "select uid, name from user where uid in (select fromid from #query2)"
                )
                result.size.should == 3
                result.keys.should include("query1", "query2", "query3")
              end
            end
          end
        end

        describe "#search" do
          it "performs a Facebook search" do
            result = @api.search("facebook")
            result.length.should be_an(Integer)
          end

          it "gets a GraphCollection when searching" do
            result = @api.search("facebook")
            result.should be_a(Koala::Facebook::GraphCollection)
          end

          it "returns nil if the search call fails with nil" do
            # this happens sometimes
            @api.should_receive(:graph_call).and_return(nil)
            @api.search("facebook").should be_nil
          end
        end
      end
    end
  end
end
