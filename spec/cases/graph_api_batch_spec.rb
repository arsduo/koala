require 'spec_helper'

describe "Koala::Facebook::GraphAPI in batch mode" do
  include LiveTestingDataHelper
  before :each do
    @api = Koala::Facebook::GraphAPI.new(@token)
    # app API
    @oauth_data = $testing_data["oauth_test_data"]
    @app_id = @oauth_data["app_id"]
    @app_access_token = @oauth_data["app_access_token"]
    @app_api = Koala::Facebook::GraphAPI.new(@app_access_token)
  end 
  
  describe "BatchOperations" do
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
    
    describe "#new" do
      it "makes http_options accessible" do
        Koala::Facebook::BatchOperation.new(@args).http_options.should == @args[:http_options]
      end
      
      it "makes post_processing accessible" do
        Koala::Facebook::BatchOperation.new(@args).post_processing.should == @args[:post_processing]
      end
      
      it "makes access_token accessible" do
        Koala::Facebook::BatchOperation.new(@args).access_token.should == @args[:access_token]
      end
            
      it "doesn't change the original http_options" do
        @args[:http_options][:name] = "baz2"
        expected = @args[:http_options].dup
        Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)
        @args[:http_options].should == expected
      end
      
      it "raises a KoalaError if no access token supplied" do
        expect { Koala::Facebook::BatchOperation.new(@args.merge(:access_token => nil)) }.to raise_exception(Koala::KoalaError)
      end
    end
    
    describe ".to_batch_params" do    
      describe "handling arguments and URLs" do
        shared_examples_for "request with no body" do
          it "adds the args to the URL string, with ? if no args previously present" do
            test_args = "foo"
            @args[:url] = url = "/"
            Koala.stub(:encode_params).and_return(test_args)
          
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == "#{url}?#{test_args}"
          end
        
          it "adds the args to the URL string, with & if args previously present" do
            test_args = "foo"
            @args[:url] = url = "/?a=2"
            Koala.stub(:encode_params).and_return(test_args)
          
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == "#{url}&#{test_args}"
          end
          
          it "adds nothing to the URL string if there are no args to be added" do
            @args[:args] = {}
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(@args[:access_token])[:relative_url].should == @args[:url]            
          end
          
          it "adds nothing to the body" do
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:body].should be_nil
          end
        end
        
        shared_examples_for "requests with a body param" do
          it "sets the body to the encoded args string, if there are args" do
            test_args = "foo"
            Koala.stub(:encode_params).and_return(test_args)
          
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:body].should == test_args
          end
          
          it "does not set the body if there are no args" do
            test_args = ""
            Koala.stub(:encode_params).and_return(test_args)
            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:body].should be_nil
          end
          
        
          it "doesn't change the url" do
            test_args = "foo"
            Koala.stub(:encode_params).and_return(test_args)

            Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)[:relative_url].should == @args[:url]
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
         params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)
         params[:relative_url].should =~ /access_token=#{@args[:access_token]}/
      end

      it "includes the other arguments if the token is not the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)
        params[:relative_url].should =~ /a=2/
      end

      it "does not include the access token if the token is the main one for the request" do
         params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(@args[:access_token])
         params[:relative_url].should_not =~ /access_token=#{@args[:access_token]}/
      end
      
      it "includes the other arguments if the token is the main one for the request" do
        @args[:args] = {:a => 2}
        params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(@args[:access_token])
        params[:relative_url].should =~ /a=2/
      end
      
      it "includes any arguments passed as http_options[:batch_args]" do
        batch_args = {:name => "baz", :foo => "bar"}
        @args[:http_options][:batch_args] = batch_args
        params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(nil)
        params.should include(batch_args)
      end

      it "includes the method" do
        params = Koala::Facebook::BatchOperation.new(@args).to_batch_params(@args[:access_token])
        params[:method].should == @args[:method].to_sym
      end
      
      it "works with nil http_options" do
        expect { Koala::Facebook::BatchOperation.new(@args.merge(:http_options => nil)).to_batch_params(nil) }.not_to raise_exception
      end
      
      it "works with nil args" do
        expect { Koala::Facebook::BatchOperation.new(@args.merge(:args => nil)).to_batch_params(nil) }.not_to raise_exception
      end      
    end
    
  end
  
  describe "GraphAPI batch interface" do
    it "sets the batch_mode flag to false outside batch mode" do
      Koala::Facebook::GraphAPI.batch_mode?.should be_false
    end
  
    it "sets the batch_mode flag inside batch mode" do
      Koala::Facebook::GraphAPI.batch do
        Koala::Facebook::GraphAPI.batch_mode?.should be_true
      end
    end
    
    it "throws an error if you try to access the batch_calls queue outside a batch block" do
      expect { Koala::Facebook::GraphAPI.batch_calls << BatchOperation.new(:access_token => "2") }.to raise_exception(Koala::KoalaError)
    end

    it "clears the batch queue between requests" do
      Koala.stub(:make_request).and_return(Koala::Response.new(200, "[]", {}))
      Koala::Facebook::GraphAPI.batch { @api.get_object("me") }
      Koala.should_receive(:make_request).once.and_return(Koala::Response.new(200, "[]", {}))
      Koala::Facebook::GraphAPI.batch { @api.get_object("me") }      
    end
    
    it "creates a BatchObject when making a GraphAPI request in batch mode" do
      Koala.should_receive(:make_request).once.and_return(Koala::Response.new(200, "[]", {}))
      
      args = {:a => :b}
      method = "post"
      http_options = {:option => true}
      url = "/a"
      access_token = "token"
      post_processing = lambda {}
      op = Koala::Facebook::BatchOperation.new(:access_token => access_token, :method => :get, :url => "/")
      Koala::Facebook::BatchOperation.should_receive(:new).with(
        :url => url,
        :args => args,
        :method => method,
        :access_token => access_token,
        :http_options => http_options,
        :post_processing => post_processing
      ).and_return(op)
      
      Koala::Facebook::GraphAPI.batch do
        Koala::Facebook::GraphAPI.new(access_token).graph_call(url, args, method, http_options, &post_processing)
      end
    end

    describe "#batch_api" do
      before :each do
        @fake_response = Koala::Response.new(200, "[]", {})
        Koala.stub(:make_request).and_return(@fake_response)
      end
      
      describe "making the request" do
        context "with no calls" do
          it "does not make any requests if batch_calls is empty" do
            Koala.should_not_receive(:make_request)
            Koala::Facebook::GraphAPI.batch {}
          end

          it "returns []" do
            Koala::Facebook::GraphAPI.batch {}.should == []        
          end
        end
      
        it "includes the first operation's access token as the main one in the args" do
          access_token = "foo"
          Koala.should_receive(:make_request).with(anything, hash_including("access_token" => access_token), anything, anything).and_return(@fake_response)
          Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new(access_token).get_object('me')
            Koala::Facebook::GraphAPI.new("bar").get_object('me')
          end
        end

        it "sets args['batch'] to a json'd map of all the batch params" do
          access_token = "bar"
          op = Koala::Facebook::BatchOperation.new(:access_token => access_token, :method => :get, :url => "/")
          op.stub(:to_batch_params).and_return({:a => 2})
          Koala::Facebook::BatchOperation.stub(:new).and_return(op)
        
          # two requests should generate two batch operations
          expected = [op.to_batch_params(access_token), op.to_batch_params(access_token)].to_json
          Koala.should_receive(:make_request).with(anything, hash_including("batch" => expected), anything, anything).and_return(@fake_response)
          Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new(access_token).get_object('me')
            Koala::Facebook::GraphAPI.new(access_token).get_object('me')
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
          Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new(access_token).get_connections('me', "farglebarg")
            Koala::Facebook::GraphAPI.new(access_token).get_connections('otheruser', "bababa")
          end
        end
      
        it "makes a POST request" do
          Koala.should_receive(:make_request).with(anything, anything, "post", anything).and_return(@fake_response)
          Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new("foo").get_object('me')
          end
        end
      
        it "makes a request to /" do
          Koala.should_receive(:make_request).with("/", anything, anything, anything).and_return(@fake_response)
          Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new("foo").get_object('me')
          end
        end
      
        it "includes any http options specified at the top level" do
          http_options = {"a" => "baz"}
          Koala.should_receive(:make_request).with(anything, anything, anything, hash_including(http_options)).and_return(@fake_response)
          Koala::Facebook::GraphAPI.batch(http_options) do
            Koala::Facebook::GraphAPI.new("foo").get_object('me')
          end
        end
      end
      
      describe "processing the request" do
        it "throws an error if the response is not 200" do
          Koala.stub(:make_request).and_return(Koala::Response.new(500, "[]", {}))
          expect { Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new("foo").get_object('me')
          end }.to raise_exception(Koala::Facebook::APIError)
        end
        
        it "throws an error if the response is a Batch API-style error" do
          Koala.stub(:make_request).and_return(Koala::Response.new(200, '{"error":190,"error_description":"Error validating access token."}', {}))
          expect { Koala::Facebook::GraphAPI.batch do
            Koala::Facebook::GraphAPI.new("foo").get_object('me')
          end }.to raise_exception(Koala::Facebook::APIError)  
        end
        
        it "returns the result status if http_component is status" do
          Koala.stub(:make_request).and_return(Koala::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = Koala::Facebook::GraphAPI.batch do
            @api.get_object("koppel", {}, :http_component => :status)
          end
          result[0].should == 203
        end

        it "returns the result headers as a hash if http_component is headers" do
          Koala.stub(:make_request).and_return(Koala::Response.new(200, '[{"code":203,"headers":[{"name":"Content-Type","value":"text/javascript; charset=UTF-8"}],"body":"{\"id\":\"1234\"}"}]', {}))
          result = Koala::Facebook::GraphAPI.batch do
            @api.get_object("koppel", {}, :http_component => :headers)
          end
          result[0].should == {"Content-Type" => "text/javascript; charset=UTF-8"}
        end
      end
      
      it "is not available on the GraphAndRestAPI class" do
        Koala::Facebook::GraphAndRestAPI.should_not respond_to(:batch)
      end
    end
  end
  
  describe "usage tests" do
    it "should be able get two results at once" do
      me, koppel = Koala::Facebook::GraphAPI.batch do
        @api.get_object('me')
        @api.get_object('koppel')
      end
      me['id'].should_not be_nil
      koppel['id'].should_not be_nil
    end

      
    it "works with GraphAndRestAPI instances" do
      me, koppel = Koala::Facebook::GraphAPI.batch do
        Koala::Facebook::GraphAndRestAPI.new(@api.access_token).get_object('me')
        @api.get_object('koppel')
      end
      me['id'].should_not be_nil
      koppel['id'].should_not be_nil
    end

    it 'should be able to make mixed calls inside of a batch' do
      me, friends = Koala::Facebook::GraphAPI.batch do
        @api.get_object('me')
        @api.get_connections('me', 'friends')
      end
      me['id'].should_not be_nil
      friends.should be_an(Array)
    end

    it 'should be able to make a get_picture call inside of a batch' do
      pictures = Koala::Facebook::GraphAPI.batch do
        @api.get_picture('me')
      end
      pictures.first.should_not be_empty
    end
    
    it "should handle requests for two different tokens" do
      me, insights = Koala::Facebook::GraphAPI.batch do
        @api.get_object('me')
        @app_api.get_connections(@app_id, 'insights')
      end
      me['id'].should_not be_nil
      insights.should be_an(Array)
    end
    
    it "inserts errors in the appropriate place, without breaking other results" do
      failed_insights, koppel = Koala::Facebook::GraphAPI.batch do
        @api.get_connections(@app_id, 'insights')
        @app_api.get_object("koppel")
      end
      failed_insights.should be_a(Koala::Facebook::APIError)
      koppel["id"].should_not be_nil
    end

    it "uploads binary files appropriately"
    
    it "handles different request methods" do
      result = @api.put_wall_post("Hello, world, from the test suite batch API!")
      wall_post = result["id"]
      
      wall_post, koppel = Koala::Facebook::GraphAPI.batch do
        @api.put_like(wall_post)
        @api.delete_object(wall_post)
      end
    end
    
    it "allows FQL" do
      result = Koala::Facebook::GraphAPI.batch do
        @api.graph_call("method/fql.query", {:query=>"select name from user where uid=4"}, "post")
      end
      
      fql_result = result[0]
      fql_result[0].should be_a(Hash)
      fql_result[0]["name"].should == "Mark Zuckerberg"
    end
    
    
    describe "relating requests" do
      it "allows you create relationships between requests without omit_response_on_success" do
        results = Koala::Facebook::GraphAPI.batch do
          @api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends"})
          @api.get_objects("{result=get-friends:$.data.*.id}")
        end
      
        results[0].should be_nil
        results[1].should be_an(Hash)
      end
      
      it "allows you create relationships between requests with omit_response_on_success" do
        results = Koala::Facebook::GraphAPI.batch do
          @api.get_connections("me", "friends", {:limit => 5}, :batch_args => {:name => "get-friends", :omit_response_on_success => false})
          @api.get_objects("{result=get-friends:$.data.*.id}")
        end
      
        results[0].should be_an(Array)
        results[1].should be_an(Hash)
      end
      
      it "allows you to create dependencies" do
        me, koppel = Koala::Facebook::GraphAPI.batch do
          @api.get_object("me", {}, :batch_args => {:name => "getme"})
          @api.get_object("koppel", {}, :batch_args => {:depends_on => "getme"})
        end
        
        me.should be_nil # gotcha!  it's omitted because it's a successfully-executed dependency
        koppel["id"].should_not be_nil
      end
      
      it "properly handles dependencies that fail" do
        data, koppel = Koala::Facebook::GraphAPI.batch do
          @api.get_connections(@app_id, 'insights', {}, :batch_args => {:name => "getdata"})
          @api.get_object("koppel", {}, :batch_args => {:depends_on => "getdata"})
        end

        data.should be_a(Koala::Facebook::APIError)
        koppel.should be_nil
      end
      
      it "throws an error for badly-constructed request relationships" do
        expect { 
          Koala::Facebook::GraphAPI.batch do
            @api.get_connections("me", "friends", {:limit => 5})
            @api.get_objects("{result=i-dont-exist:$.data.*.id}")
          end
        }.to raise_exception(Koala::Facebook::APIError)
      end
    end
  end
end