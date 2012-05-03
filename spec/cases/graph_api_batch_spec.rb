require 'spec_helper'

describe "Koala::Facebook::GraphAPI in batch mode" do

  before :each do
    @api = Koala::Facebook::API.new(@token)
    # app API
    @app_id = KoalaTest.app_id
    @app_access_token = KoalaTest.app_access_token
    @app_api = Koala::Facebook::API.new(@app_access_token)
  end

  describe Koala::Facebook::GraphBatchAPI::BatchOperation do
    before :each do
      @args = {
        :url => "my url",
        :args => {:a => 2, :b => 3},
        :method => "get",
        :access_token => "12345",
        :http_options => {},
        :post_processing => lambda { }
      }
    end

    describe ".new" do
      it "makes http_options accessible" do
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).http_options.should == @args[:http_options]
      end

      it "makes post_processing accessible" do
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).post_processing.should == @args[:post_processing]
      end

      it "makes access_token accessible" do
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).access_token.should == @args[:access_token]
      end

      it "doesn't change the original http_options" do
        @args[:http_options][:name] = "baz2"
        expected = @args[:http_options].dup
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)
        @args[:http_options].should == expected
      end

      it "leaves the file array nil by default" do
        Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).files.should be_nil
      end

      it "raises a KoalaError if no access token supplied" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:access_token => nil)) }.to raise_exception(Koala::KoalaError)
      end

      describe "when supplied binary files" do
        before :each do
          @binary = stub("Binary file")
          @uploadable_io = stub("UploadableIO 1")

          @batch_queue = []
          Koala::Facebook::GraphAPI.stub(:batch_calls).and_return(@batch_queue)

          Koala::UploadableIO.stub(:new).with(@binary).and_return(@uploadable_io)
          Koala::UploadableIO.stub(:binary_content?).and_return(false)
          Koala::UploadableIO.stub(:binary_content?).with(@binary).and_return(true)
          Koala::UploadableIO.stub(:binary_content?).with(@uploadable_io).and_return(true)
          @uploadable_io.stub(:is_a?).with(Koala::UploadableIO).and_return(true)

          @args[:method] = "post" # files are always post
        end

        it "adds binary files to the files attribute as UploadableIOs" do
          @args[:args].merge!("source" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          batch_op.files.should_not be_nil
          batch_op.files.find {|k, v| v == @uploadable_io}.should_not be_nil
        end

        it "works if supplied an UploadableIO as an argument" do
          # as happens with put_picture at the moment
          @args[:args].merge!("source" => @uploadable_io)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          batch_op.files.should_not be_nil
          batch_op.files.find {|k, v| v == @uploadable_io}.should_not be_nil
        end

        it "assigns each binary parameter unique name" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          # if the name wasn't unique, there'd just be one item
          batch_op.files.should have(2).items
        end

        it "assigns each binary parameter unique name across batch requests" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          # simulate the batch operation, since it's used in determination
          @batch_queue << batch_op
          batch_op2 = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          @batch_queue << batch_op2
          # if the name wasn't unique, we should have < 4 items since keys would be the same
          batch_op.files.merge(batch_op2.files).should have(4).items
        end

        it "removes the value from the arguments" do
          @args[:args].merge!("source" => @binary)
          Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:body].should_not =~ /source=/
        end
      end

    end

    describe "#to_batch_params" do
      describe "handling arguments and URLs" do
        shared_examples_for "request with no body" do
          it "adds the args to the URL string, with ? if no args previously present" do
            test_args = "foo"
            @args[:url] = url = "/"
            Koala.http_service.stub(:encode_params).and_return(test_args)

            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == "#{url}?#{test_args}"
          end

          it "adds the args to the URL string, with & if args previously present" do
            test_args = "foo"
            @args[:url] = url = "/?a=2"
            Koala.http_service.stub(:encode_params).and_return(test_args)

            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == "#{url}&#{test_args}"
          end

          it "adds nothing to the URL string if there are no args to be added" do
            @args[:args] = {}
            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token])[:relative_url].should == @args[:url]
          end

          it "adds nothing to the body" do
            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:body].should be_nil
          end
        end

        shared_examples_for "requests with a body param" do
          it "sets the body to the encoded args string, if there are args" do
            test_args = "foo"
            Koala.http_service.stub(:encode_params).and_return(test_args)

            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:body].should == test_args
          end

          it "does not set the body if there are no args" do
            test_args = ""
            Koala.http_service.stub(:encode_params).and_return(test_args)
            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:body].should be_nil
          end


          it "doesn't change the url" do
            test_args = "foo"
            Koala.http_service.stub(:encode_params).and_return(test_args)

            Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == @args[:url]
          end
        end

        context "for get operations" do
          before :each do
            @args[:method] = :get
          end

          it_should_behave_like "request with no body"
        end

        context "for delete operations" do
          before :each do
            @args[:method] = :delete
          end

          it_should_behave_like "request with no body"
        end

        context "for get operations" do
          before :each do
            @args[:method] = :put
          end

          it_should_behave_like "requests with a body param"
        end

        context "for delete operations" do
          before :each do
            @args[:method] = :post
          end

          it_should_behave_like "requests with a body param"
        end
      end

      it "includes the access token if the token is not the main one for the request" do
         params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)
         params[:relative_url].should =~ /access_token=#{@args[:access_token]}/
      end

      it "includes the other arguments if the token is not the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)
        params[:relative_url].should =~ /a=2/
      end

      it "does not include the access token if the token is the main one for the request" do
         params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token])
         params[:relative_url].should_not =~ /access_token=#{@args[:access_token]}/
      end

      it "includes the other arguments if the token is the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token])
        params[:relative_url].should =~ /a=2/
      end

      it "includes any arguments passed as http_options[:batch_args]" do
        batch_args = {:name => "baz", :headers => {:some_param => true}}
        @args[:http_options][:batch_args] = batch_args
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(nil)
        params.should include(batch_args)
      end

      it "includes the method" do
        params = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args).to_batch_params(@args[:access_token])
        params[:method].should == @args[:method].to_s
      end

      it "works with nil http_options" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:http_options => nil)).to_batch_params(nil) }.not_to raise_exception
      end

      it "works with nil args" do
        expect { Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args.merge(:args => nil)).to_batch_params(nil) }.not_to raise_exception
      end

      describe "with binary files" do
        before :each do
          @binary = stub("Binary file")
          Koala::UploadableIO.stub(:binary_content?).and_return(false)
          Koala::UploadableIO.stub(:binary_content?).with(@binary).and_return(true)
          @uploadable_io = stub("UploadableIO")
          Koala::UploadableIO.stub(:new).with(@binary).and_return(@uploadable_io)
          @uploadable_io.stub(:is_a?).with(Koala::UploadableIO).and_return(true)

          @batch_queue = []
          Koala::Facebook::GraphAPI.stub(:batch_calls).and_return(@batch_queue)

          @args[:method] = "post" # files are always post
        end

        it "adds file identifiers as attached_files in a comma-separated list" do
          @args[:args].merge!("source" => @binary, "source2" => @binary)
          batch_op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(@args)
          file_ids = batch_op.files.find_all {|k, v| v == @uploadable_io}.map {|k, v| k}
          params = batch_op.to_batch_params(nil)
          params[:attached_files].should == file_ids.join(",")
        end
      end
    end

  end

  describe "GraphAPI batch interface" do
    it "returns nothing for a batch operation" do
      Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(200, "[]", {}))
      @api.batch do |batch_api|
        batch_api.get_object('me').should be_nil
      end
    end

    describe "#batch" do
      before :each do
        @fake_response = Koala::HTTPService::Response.new(200, "[]", {})
        Koala.stub(:make_request).and_return(@fake_response)
      end

      describe "making the request" do
        context "with no calls" do
          it "does not make any requests if batch_calls is empty" do
            Koala.should_not_receive(:make_request)
            @api.batch {|batch_api|}
          end

          it "returns []" do
            @api.batch {|batch_api|}.should == []
          end
        end

        it "includes the first operation's access token as the main one in the args" do
          access_token = "foo"
          Koala.should_receive(:make_request).with(anything, hash_including("access_token" => access_token), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_object('me')
            batch_api.get_object('me', {}, {'access_token' => 'bar'})
          end
        end

        it "sets args['batch'] to a json'd map of all the batch params" do
          access_token = "bar"
          op = Koala::Facebook::GraphBatchAPI::BatchOperation.new(:access_token => access_token, :method => :get, :url => "/")
          op.stub(:to_batch_params).and_return({:a => 2})
          Koala::Facebook::GraphBatchAPI::BatchOperation.stub(:new).and_return(op)

          # two requests should generate two batch operations
          expected = MultiJson.dump([op.to_batch_params(access_token), op.to_batch_params(access_token)])
          Koala.should_receive(:make_request).with(anything, hash_including("batch" => expected), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_object('me')
            batch_api.get_object('me')
          end
        end

        it "adds any files from the batch operations to the arguments" do
          # stub the batch operation
          # we test above to ensure that files are properly assimilated into the BatchOperation instance
          # right now, we want to make sure that batch_api handles them properly
          @key = "file0_0"
          @uploadable_io = stub("UploadableIO")
          batch_op = stub("Koala Batch Operation", :files => {@key => @uploadable_io}, :to_batch_params => {}, :access_token => "foo")
          Koala::Facebook::GraphBatchAPI::BatchOperation.stub(:new).and_return(batch_op)

          Koala.should_receive(:make_request).with(anything, hash_including(@key => @uploadable_io), anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new("bar").batch do |batch_api|
            batch_api.put_picture("path/to/file", "image/jpeg")
          end
        end

        it "preserves operation order" do
          access_token = "bar"
          # two requests should generate two batch operations
          Koala.should_receive(:make_request) do |url, args, method, options|
            # test the batch operations to make sure they appear in the right order
            (args ||= {})["batch"].should =~ /.*me\/farglebarg.*otheruser\/bababa/
            @fake_response
          end
          Koala::Facebook::API.new(access_token).batch do |batch_api|
            batch_api.get_connections('me', "farglebarg")
            batch_api.get_connections('otheruser', "bababa")
          end
        end

        it "makes a POST request" do
          Koala.should_receive(:make_request).with(anything, anything, "post", anything).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch do |batch_api|
            batch_api.get_object('me')
          end
        end

        it "makes a request to /" do
          Koala.should_receive(:make_request).with("/", anything, anything, anything).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch do |batch_api|
            batch_api.get_object('me')
          end
        end

        it "includes any http options specified at the top level" do
          http_options = {"a" => "baz"}
          Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(http_options)).and_return(@fake_response)
          Koala::Facebook::API.new("foo").batch(http_options) do |batch_api|
            batch_api.get_object('me')
          end
        end
      end

      describe "processing the request" do
        it "returns the result headers as a hash if http_component is headers" do
          Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = @api.batch do |batch_api|
            batch_api.get_object(KoalaTest.user1, {}, :http_component => :headers)
          end
          result[0].should == {"Content-Type" => "text/javascript; charset=UTF-8"}
        end

        describe "if it errors" do
          it "raises an APIError if the response is not 200" do
            Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(500, "[]", {}))
            expect {
              Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
            }.to raise_exception(Koala::Facebook::APIError)
          end

          it "raises a BadFacebookResponse if the body is empty" do
            Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(200, "", {}))
            expect {
              Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
            }.to raise_exception(Koala::Facebook::BadFacebookResponse)
          end

          context "with the old style" do
            before :each do
              Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(400, '{"error_code":190,"error_description":"Error validating access token."}', {}))
            end

            it "throws an error" do
              expect {
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              }.to raise_exception(Koala::Facebook::APIError)
            end

            it "passes all the error details" do
              begin
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              rescue Koala::Facebook::APIError => err
                err.fb_error_code.should == 190
                err.fb_error_message.should == "Error validating access token."
                err.http_status == 400
                err.response_body == '{"error_code":190,"error_description":"Error validating access token."}'
              end
            end
          end

          context "with the new style" do
            before :each do
              Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(400, '{"error":{"message":"Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests","type":"GraphBatchException"}}', {}))
            end

            it "throws an error" do
              expect {
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              }.to raise_exception(Koala::Facebook::APIError)
            end

            it "passes all the error details" do
              begin
                Koala::Facebook::API.new("foo").batch {|batch_api| batch_api.get_object('me') }
              rescue Koala::Facebook::APIError => err
                err.fb_error_type.should == "GraphBatchException"
                err.fb_error_message.should == "Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests"
                err.http_status == 400
                err.response_body == '{"error":{"message":"Request 0 cannot depend on an  unresolved request with  name f. Requests can only depend on preceding requests","type":"GraphBatchException"}}'
              end
            end
          end
        end

        it "returns the result status if http_component is status" do
          Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = @api.batch do |batch_api|
            batch_api.get_object(KoalaTest.user1, {}, :http_component => :status)
          end
          result[0].should == 203
        end
      end

      it "is thread safe" do
        # ensure batch operations on one thread don't affect those on another
        thread_one_count = 0
        thread_two_count = 0
        first_count = 20
        second_count = 10

        Koala.stub(:make_request).and_return(@fake_response)

        thread1 = Thread.new do
          @api.batch do |batch_api|
            first_count.times {|i| batch_api.get_object("me"); sleep(0.01) }
            thread_one_count = batch_api.batch_calls.count
          end
        end

        thread2 = Thread.new do
          @api.batch do |batch_api|
            second_count.times {|i| batch_api.get_object("me"); sleep(0.01) }
            thread_two_count = batch_api.batch_calls.count
          end
        end

        thread1.join
        thread2.join

        thread_one_count.should == first_count
        thread_two_count.should == second_count
      end
    end
  end

  describe "usage tests" do
    it "gets two results at once" do
      me, koppel = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_object(KoalaTest.user1)
      end
      me['id'].should_not be_nil
      koppel['id'].should_not be_nil
    end

    it 'makes mixed calls inside of a batch' do
      me, friends = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections('me', 'friends')
      end
      friends.should be_a(Koala::Facebook::GraphCollection)
    end

    it 'turns pageable results into GraphCollections' do
      me, friends = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections('me', 'friends')
      end
      me['id'].should_not be_nil
      friends.should be_an(Array)
    end

    it 'makes a get_picture call inside of a batch' do
      pictures = @api.batch do |batch_api|
        batch_api.get_picture('me')
      end
      pictures.first.should_not be_empty
    end

    it "handles requests for two different tokens" do
      me, insights = @api.batch do |batch_api|
        batch_api.get_object('me')
        batch_api.get_connections(@app_id, 'insights', {}, {"access_token" => @app_api.access_token})
      end
      me['id'].should_not be_nil
      insights.should be_an(Array)
    end

    it "inserts errors in the appropriate place, without breaking other results" do
      failed_call, koppel = @api.batch do |batch_api|
        batch_api.get_connection("2", "invalidconnection")
        batch_api.get_object(KoalaTest.user1, {}, {"access_token" => @app_api.access_token})
      end
      failed_call.should be_a(Koala::Facebook::ClientError)
      koppel["id"].should_not be_nil
    end

    it "handles different request methods" do
      result = @api.put_wall_post("Hello, world, from the test suite batch API!")
      wall_post = result["id"]

      wall_post, koppel = @api.batch do |batch_api|
        batch_api.put_like(wall_post)
        batch_api.delete_object(wall_post)
      end
    end

    it "allows FQL" do
      result = @api.batch do |batch_api|
        batch_api.graph_call("method/fql.query", {:query=>"select first_name from user where uid=#{KoalaTest.user1_id}"}, "post")
      end

      fql_result = result[0]
      fql_result[0].should be_a(Hash)
      fql_result[0]["first_name"].should == "Alex"
    end

    describe "binary files" do
      it "posts binary files" do
        file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

        Koala::Facebook::GraphBatchAPI::BatchOperation.instance_variable_set(:@identifier, 0)
        result = @api.batch do |batch_api|
          batch_api.put_picture(file)
        end

        @temporary_object_id = result[0]["id"]
        @temporary_object_id.should_not be_nil
      end

      it "posts binary files with multiple requests" do
        file = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))
        file2 = File.open(File.join(File.dirname(__FILE__), "..", "fixtures", "beach.jpg"))

        Koala::Facebook::GraphBatchAPI::BatchOperation.instance_variable_set(:@identifier, 0)
        results = @api.batch do |batch_api|
          batch_api.put_picture(file)
          batch_api.put_picture(file2, {}, KoalaTest.user1)
        end
        results[0]["id"].should_not be_nil
        results[1]["id"].should_not be_nil
      end
    end

    describe "relating requests" do
      it "allows you create relationships between requests without omit_response_on_success" do
        results = @api.batch do |batch_api|
          batch_api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends"})
          batch_api.get_objects("{result=get-friends:$.data.*.id}")
        end

        results[0].should be_nil
        results[1].should be_an(Hash)
      end

      it "allows you create relationships between requests with omit_response_on_success" do
        results = @api.batch do |batch_api|
          batch_api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends", :omit_response_on_success => false})
          batch_api.get_objects("{result=get-friends:$.data.*.id}")
        end

        results[0].should be_an(Array)
        results[1].should be_an(Hash)
      end

      it "allows you to create dependencies" do
        me, koppel = @api.batch do |batch_api|
          batch_api.get_object("me", {}, :batch_args => {:name => "getme"})
          batch_api.get_object(KoalaTest.user1, {}, :batch_args => {:depends_on => "getme"})
        end

        me.should be_nil # gotcha!  it's omitted because it's a successfully-executed dependency
        koppel["id"].should_not be_nil
      end

      it "properly handles dependencies that fail" do
        failed_call, koppel = @api.batch do |batch_api|
          batch_api.get_connections("2", "invalidconnection", {}, :batch_args => {:name => "getdata"})
          batch_api.get_object(KoalaTest.user1, {}, :batch_args => {:depends_on => "getdata"})
        end

        failed_call.should be_a(Koala::Facebook::ClientError)
        koppel.should be_nil
      end

      it "throws an error for badly-constructed request relationships" do
        expect {
          @api.batch do |batch_api|
            batch_api.get_connections("me", "friends", {:limit => 5})
            batch_api.get_objects("{result=i-dont-exist:$.data.*.id}")
          end
        }.to raise_exception(Koala::Facebook::ClientError)
      end
    end
  end
end