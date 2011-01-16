require 'koala/http_services'
class TyphoeusServiceTests < Test::Unit::TestCase
  module Bear
    include Koala::TyphoeusService
  end

  describe "TyphoeusService module holder class Bear" do
    before :each do
      # reset the always_use_ssl parameter
      Bear.always_use_ssl = nil
    end

    it "should define a make_request static module method" do
      Bear.respond_to?(:make_request).should be_true
    end

    it "should include the Koala::HTTPService module defining common features" do
      Bear.included_modules.include?(Koala::HTTPService).should be_true
    end

    describe "when making a request" do
      before(:each) do
        # Setup stubs for make_request to execute without exceptions
        @mock_body = stub('Typhoeus response body')
        @mock_headers_hash = stub({:value => "headers hash"})
        @mock_http_response = stub(Typhoeus::Response, :code => 1, :headers_hash => @mock_headers_hash, :body => @mock_body)

        # Typhoeus is an included module, so we stub methods on Bear itself
        Bear.stub(:post).and_return(@mock_http_response)
        Bear.stub(:get).and_return(@mock_http_response)
      end

      it "should use POST if verb is not GET" do
        Bear.should_receive(:post).and_return(@mock_http_response)
        Bear.make_request('anything', {}, 'anything')
      end

      it "should use GET if that verb is specified" do
        Bear.should_receive(:get).and_return(@mock_http_response)
        Bear.make_request('anything', {}, 'get')
      end

      describe "the connection" do
        it "should use SSL if the request has an access token" do
          Bear.should_receive(:post).with(/https\:/, anything)

          Bear.make_request('anything', {"access_token" => "123"}, 'anything')
        end

        it "should use SSL if always_use_ssl is true, even if there's no token" do
          Bear.should_receive(:post).with(/https\:/, anything)

          Bear.always_use_ssl = true
          Bear.make_request('anything', {}, 'anything')
        end

        it "should use SSL if the :use_ssl option is provided, even if there's no token" do
          Bear.should_receive(:post).with(/https\:/, anything)

          Bear.always_use_ssl = true
          Bear.make_request('anything', {}, 'anything', :use_ssl => true)
        end

        it "should not use SSL if always_use_ssl is false and there's no token" do
          Bear.should_receive(:post).with(/http\:/, anything)

          Bear.make_request('anything', {}, 'anything')
        end

        it "should use the graph server by default" do
          Bear.should_receive(:post).with(Regexp.new(Koala::Facebook::GRAPH_SERVER), anything)

          Bear.make_request('anything', {}, 'anything')
        end

        it "should use the REST server if the :rest_api option is true" do
          Bear.should_receive(:post).with(Regexp.new(Koala::Facebook::REST_SERVER), anything)

          Bear.make_request('anything', {}, 'anything', :rest_api => true)
        end
      end

      it "should pass the arguments to Typhoeus under the :params key" do
        args = {:a => 2}
        Bear.should_receive(:post).with(anything, hash_including(:params => args))

        Bear.make_request('anything', args, "post")
      end

      it "should add the method to the arguments if the method isn't get or post" do
        method = "telekenesis"
        Bear.should_receive(:post).with(anything, hash_including(:params => {:method => method}))

        Bear.make_request('anything', {}, method)
      end

      it "should pass :typhoeus_options to Typhoeus if provided" do
        t_options = {:a => :b}
        Bear.should_receive(:post).with(anything, hash_including(t_options))

        Bear.make_request("anything", {}, "post", :typhoeus_options => t_options)
      end

      it "should include the path in the request" do
        path = "/a/b/c/1"
        Bear.should_receive(:post).with(Regexp.new(path), anything)

        Bear.make_request(path, {}, "post")
      end

      describe "the returned value" do
        before(:each) do
          @response = Bear.make_request('anything', {}, 'anything')
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

        it "should return a Koala::Response with the Net::HTTPResponse object as headers" do
          @response.headers.should == @mock_headers_hash
        end
      end # describe return value

    end
  end
end