require 'spec_helper'


Deer = Koala::TyphoeusService

describe "TyphoeusService" do

  describe "TyphoeusService module holder class Deer" do
    before :each do
      # reset global settings
      Deer.always_use_ssl = Deer.proxy = Deer.timeout = nil
    end

    it "should define a make_request static module method" do
      Deer.respond_to?(:make_request).should be_true
    end

    it "should include the Koala::HTTPService module defining common features" do
      Deer.included_modules.include?(Koala::HTTPService).should be_true
    end

    describe "when making a request" do
      before(:each) do
        # Setup stubs for make_request to execute without exceptions
        @mock_body = stub('Typhoeus response body')
        @mock_headers_hash = stub({:value => "headers hash"})
        @mock_http_response = stub(Typhoeus::Response, :code => 1, :headers_hash => @mock_headers_hash, :body => @mock_body)

        # Typhoeus is an included module, so we stub methods on Deer itself
        Typhoeus::Request.stub(:post).and_return(@mock_http_response)
        Typhoeus::Request.stub(:get).and_return(@mock_http_response)
      end

      it "should use POST if verb is not GET" do
        Typhoeus::Request.should_receive(:post).and_return(@mock_http_response)
        Deer.make_request('anything', {}, 'anything')
      end

      it "should use GET if that verb is specified" do
        Typhoeus::Request.should_receive(:get).and_return(@mock_http_response)
        Deer.make_request('anything', {}, 'get')
      end

      describe "the connection" do
        it "should use SSL if the request has an access token" do
          Typhoeus::Request.should_receive(:post).with(/https\:/, anything)

          Deer.make_request('anything', {"access_token" => "123"}, 'anything')
        end

        it "should use SSL if always_use_ssl is true, even if there's no token" do
          Typhoeus::Request.should_receive(:post).with(/https\:/, anything)

          Deer.always_use_ssl = true
          Deer.make_request('anything', {}, 'anything')
        end

        it "should use SSL if the :use_ssl option is provided, even if there's no token" do
          Typhoeus::Request.should_receive(:post).with(/https\:/, anything)

          Deer.always_use_ssl = true
          Deer.make_request('anything', {}, 'anything', :use_ssl => true)
        end

        it "should not use SSL if always_use_ssl is false and there's no token" do
          Typhoeus::Request.should_receive(:post).with(/http\:/, anything)

          Deer.make_request('anything', {}, 'anything')
        end

        it "should use the graph server by default" do
          Typhoeus::Request.should_receive(:post).with(Regexp.new(Koala::Facebook::GRAPH_SERVER), anything)

          Deer.make_request('anything', {}, 'anything')
        end

        it "should use the REST server if the :rest_api option is true" do
          Typhoeus::Request.should_receive(:post).with(Regexp.new(Koala::Facebook::REST_SERVER), anything)

          Deer.make_request('anything', {}, 'anything', :rest_api => true)
        end
      end

      it "should pass the arguments to Typhoeus under the :params key" do
        args = {:a => 2}
        Typhoeus::Request.should_receive(:post).with(anything, hash_including(:params => args))

        Deer.make_request('anything', args, "post")
      end

      it "should add the method to the arguments if the method isn't get or post" do
        method = "telekenesis"
        Typhoeus::Request.should_receive(:post).with(anything, hash_including(:params => {:method => method}))

        Deer.make_request('anything', {}, method)
      end

      it "should pass :typhoeus_options to Typhoeus if provided" do
        t_options = {:a => :b}
        Typhoeus::Request.should_receive(:post).with(anything, hash_including(t_options))

        Deer.make_request("anything", {}, "post", :typhoeus_options => t_options)
      end

      it "should pass proxy and timeout :typhoeus_options to Typhoeus if set globally" do
        Deer.proxy = "http://defaultproxy"
        Deer.timeout = 20

        t_options = {:proxy => "http://defaultproxy", :timeout => 20}
        Typhoeus::Request.should_receive(:post).with(anything, hash_including(t_options))

        Deer.make_request("anything", {}, "post")
      end

      # for live tests, run the Graph API tests with Typhoues, which will run file uploads
      it "should pass any files directly on to Typhoues" do
        args = {:file => File.new(__FILE__, "r")}
        Typhoeus::Request.should_receive(:post).with(anything, hash_including(:params => args)).and_return(Typhoeus::Response.new)
        Deer.make_request("anything", args, :post)
      end

      it "should include the path in the request" do
        path = "/a/b/c/1"
        Typhoeus::Request.should_receive(:post).with(Regexp.new(path), anything)

        Deer.make_request(path, {}, "post")
      end

      describe "the returned value" do
        before(:each) do
          @response = Deer.make_request('anything', {}, 'anything')
        end

        it "should return a Koala::Response object" do
          @response.class.should == Koala::Response
        end

        it "should return a Koala::Response with the right status" do
          @response.status.should == @mock_http_response.code
        end

        it "should reutrn a Koala::Response with the right body" do
          @response.body.should == @mock_body
        end

        it "should return a Koala::Response with the Typhoeus headers as headers" do
          @response.headers.should == @mock_headers_hash
        end
      end # describe return value
    end
  end
end