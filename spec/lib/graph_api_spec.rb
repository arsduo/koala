require 'spec_helper'

describe Koala::Facebook::GraphAPIMethods do
  before do
    @api = Koala::Facebook::API.new(@token)
    @api_without_token = Koala::Facebook::API.new
    # app API
    @app_id = KoalaTest.app_id
    @app_access_token = KoalaTest.app_access_token
    @app_api = Koala::Facebook::API.new(@app_access_token)
  end

  # Read, write, and delete behavior are tested in the appropriate api/* files
  describe "core behavior" do
    it "never uses the rest api server" do
      Koala.should_receive(:make_request).with(
        anything,
        anything,
        anything,
        hash_not_including(:rest_api => true)
      ).and_return(Koala::HTTPService::Response.new(200, "", {}))

      @api.api("anything")
    end

    it "can use the beta tier" do
      result = @api.get_object(KoalaTest.user1, {}, :beta => true)
      # the results should have an ID and a name, among other things
      (result["id"] && result["name"]).should_not be_nil
    end

    describe "#graph_call" do
      it "passes all arguments to the api method" do
        args = [KoalaTest.user1, {}, "get", {:a => :b}]
        @api.should_receive(:api).with(*args)
        @api.graph_call(*args)
      end

      it "throws an APIError if the result hash has an error key" do
        Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(500, '{"error": "An error occurred!"}', {}))
        lambda { @api.graph_call(KoalaTest.user1, {}) }.should raise_exception(Koala::Facebook::APIError)
      end

      it "passes the results through GraphCollection.evaluate" do
        result = {}
        @api.stub(:api).and_return(result)
        Koala::Facebook::GraphCollection.should_receive(:evaluate).with(result, @api)
        @api.graph_call("/me")
      end

      it "returns the results of GraphCollection.evaluate" do
        expected = {}
        @api.stub(:api).and_return([])
        Koala::Facebook::GraphCollection.should_receive(:evaluate).and_return(expected)
        @api.graph_call("/me").should == expected
      end

      it "returns the post_processing block's results if one is supplied" do
        other_result = [:a, 2, :three]
        block = Proc.new {|r| other_result}
        @api.stub(:api).and_return({})
        @api.graph_call("/me", {}, "get", {}, &block).should == other_result
      end
    end

    describe "working with GraphCollections" do
      it "makes a request for a page when provided a specific set of page params" do
        query = [1, 2]
        @api.should_receive(:graph_call).with(*query)
        @api.get_page(query)
      end

      it "returns nil if the page call fails with nil" do
        # this happens sometimes
        @api.should_receive(:graph_call).and_return(nil)
        @api.get_page(["search", {"q"=>"facebook", "limit"=>"25", "until"=> KoalaTest.search_time}]).should be_nil
      end
    end

    describe "processing results from calls" do
      let(:post_processing) { lambda {} }

      # Most API methods have the same signature, we test get_object representatively
      # and the other methods which do some post-processing locally
      context '#get_object' do
        it 'returns result of block' do
          result = {"id" => 1, "name" => 1, "updated_time" => 1}
          @api.stub(:api).and_return(result)
          post_processing.should_receive(:call).
            with(result).and_return('new result')
          @api.get_object('koppel', &post_processing).should == 'new result'
        end
      end

      context '#get_picture' do
        it 'returns result of block' do
          result = "http://facebook.com/"
          @api.stub(:api).and_return("Location" => result)
          post_processing.should_receive(:call).
            with(result).and_return('new result')
          @api.get_picture('lukeshepard', &post_processing).should == 'new result'
        end
      end

      context '#fql_multiquery' do
        before do
          @api.should_receive(:get_object).and_return([
            {"name" => "query1", "fql_result_set" => [{"id" => 123}]},
            {"name" => "query2", "fql_result_set" => ["id" => 456]}
          ])
        end

        it 'is called with resolved response' do
          resolved_result = {
            'query1' => [{'id' => 123}],
            'query2' => [{'id'=>456}]
          }
          post_processing.should_receive(:call).
            with(resolved_result).and_return('id'=>'123', 'id'=>'456')
          @api.fql_multiquery({}, &post_processing).should ==
            {'id'=>'123', 'id'=>'456'}
        end
      end

      context '#get_page_access_token' do
        it 'returns result of block' do
          token = Koala::MockHTTPService::APP_ACCESS_TOKEN
          @api.stub(:api).and_return("access_token" => token)
          post_processing.should_receive(:call).
            with(token).and_return('base64-encoded access token')
          @api.get_page_access_token('facebook', &post_processing).should ==
            'base64-encoded access token'
        end
      end
    end
    
    # test all methods to make sure they pass data through to the API
    # we run the tests here (rather than in the common shared example group)
    # since some require access tokens
    describe "providing HTTP options to control the request" do
      # Each of the below methods should take an options hash as their last argument
      # ideally we'd use introspection to determine how many arguments a method has
      # but some methods require specially formatted arguments for processing
      # (and anyway, Ruby 1.8's arity method fails (for this) for methods w/ 2+ optional arguments)
      # (Ruby 1.9's parameters method is perfect, but only in 1.9)
      # so we have to double-document
      {
        :get_object => 3, :put_object => 4, :delete_object => 2,
        :get_connections => 4, :put_connections => 4, :delete_connections => 4,
        :put_wall_post => 4,
        :put_comment => 3,
        :put_like => 2, :delete_like => 2,
        :search => 3,
        :set_app_restrictions => 4,
        :get_page_access_token => 3,
        :fql_query => 3, :fql_multiquery => 3,
        # methods that have special arguments
        :get_comments_for_urls => [["url1", "url2"], {}],
        :put_picture => ["x.jpg", "image/jpg", {}, "me"],
        :put_video => ["x.mp4", "video/mpeg4", {}, "me"],
        :get_objects => [["x"], {}]
      }.each_pair do |method_name, params|
        it "passes http options through for #{method_name}" do
          options = {:a => 2}
          # graph call should ultimately receive options as the fourth argument
          @api.should_receive(:graph_call).with(anything, anything, anything, options)

          # if we supply args, use them (since some methods process params)
          # the method should receive as args n-1 anythings and then options
          args = (params.is_a?(Integer) ? ([{}] * (params - 1)) : params) + [options]

          @api.send(method_name, *args)
        end
      end

      # also test get_picture, which merges a parameter into options
      it "passes http options through for get_picture" do
        options = {:a => 2}
        # graph call should ultimately receive options as the fourth argument
        @api.should_receive(:graph_call).with(anything, anything, anything, hash_including(options)).and_return({})
        @api.send(:get_picture, "x", {}, options)
      end
    end
  end
end
