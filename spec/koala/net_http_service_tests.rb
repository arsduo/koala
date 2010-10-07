require 'koala/http_services'
class NetHTTPServiceTests < Test::Unit::TestCase
  module Bear
    include Koala::NetHTTPService
  end

  describe "NetHTTPService module holder class Bear" do
    it "should define a make_request static module method" do
      Bear.respond_to?(:make_request).should be_true
    end

    describe "when making a request" do
      before(:each) do
        # Setup stubs for make_request to execute without exceptions
        @mock_http_response = stub('Net::HTTPResponse', :code => 1)
        @mock_body = stub('Net::HTTPResponse body')
        @http_request_result = [@mock_http_response, @mock_body]

        # to_ary is called in Ruby 1.9 to provide backwards compatibility 
        # with the response, body = http.get() syntax we use
        @mock_http_response.stub!(:to_ary).and_return(@http_request_result)

        @http_yield_mock = mock('Net::HTTP start yielded object')

        @http_yield_mock.stub(:post).and_return(@http_request_result)
        @http_yield_mock.stub(:get).and_return(@http_request_result)

        @http_mock = stub('Net::HTTP object', 'use_ssl=' => true, 'verify_mode=' => true)
        @http_mock.stub(:start).and_yield(@http_yield_mock)

        Net::HTTP.stub(:new).and_return(@http_mock)
      end

      it "should use POST if verb is not GET" do
        @http_yield_mock.should_receive(:post).and_return(@mock_http_response)
        @http_mock.should_receive(:start).and_yield(@http_yield_mock)

        Bear.make_request('anything', {}, 'anything')
      end

      it "should use port 443" do
        Net::HTTP.should_receive(:new).with(anything, 443).and_return(@http_mock)

        Bear.make_request('anything', {}, 'anything')  
      end

      it "should use SSL" do
        @http_mock.should_receive('use_ssl=').with(true)

        Bear.make_request('anything', {}, 'anything')  
      end

      it "should use the graph server by default" do
        Net::HTTP.should_receive(:new).with(Koala::Facebook::GRAPH_SERVER, anything).and_return(@http_mock)
        Bear.make_request('anything', {}, 'anything')  
      end

      it "should use the REST server if the :rest_api option is true" do
        Net::HTTP.should_receive(:new).with(Koala::Facebook::REST_SERVER, anything).and_return(@http_mock)
        Bear.make_request('anything', {}, 'anything', :rest_api => true)  
      end

      it "should turn off vertificate validaiton warnings" do
        @http_mock.should_receive('verify_mode=').with(OpenSSL::SSL::VERIFY_NONE)

        Bear.make_request('anything', {}, 'anything')
      end

      it "should start an HTTP connection" do
        @http_mock.should_receive(:start).and_yield(@http_yield_mock)
        Bear.make_request('anything', {}, 'anything')
      end

      describe "via POST" do
        it "should use Net::HTTP to make a POST request" do
          @http_yield_mock.should_receive(:post).and_return(@http_request_result)

          Bear.make_request('anything', {}, 'post')
        end

        it "should go to the specified path adding a / if it doesn't exist" do
          path = mock('Path')
          @http_yield_mock.should_receive(:post).with(path, anything).and_return(@http_request_result)

          Bear.make_request(path, {}, 'post')        
        end

        it "should use encoded parameters" do
          args = {}
          params = mock('Encoded parameters')
          Bear.should_receive(:encode_params).with(args).and_return(params)

          @http_yield_mock.should_receive(:post).with(anything, params).and_return(@http_request_result)

          Bear.make_request('anything', args, 'post')
        end
      end

      describe "via GET" do
        it "should use Net::HTTP to make a GET request" do
          @http_yield_mock.should_receive(:get).and_return(@http_request_result)

          Bear.make_request('anything', {}, 'get')
        end

        it "should use the correct path, including arguments" do
          path = mock('Path')
          params = mock('Encoded parameters')
          args = {}

          Bear.should_receive(:encode_params).with(args).and_return(params)
          @http_yield_mock.should_receive(:get).with("#{path}?#{params}").and_return(@http_request_result)

          Bear.make_request(path, args, 'get')
        end
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
          @response.headers.should == @mock_http_response
        end
      end # describe return value
    end # describe when making a request

    describe "when encoding parameters" do
      it "should return an empty string if param_hash evaluates to false" do
        Bear.encode_params(nil).should == ''
      end

      it "should convert values to JSON if the value is not a String" do
        val = 'json_value'
        not_a_string = 'not_a_string'
        not_a_string.stub(:class).and_return('NotAString')
        not_a_string.should_receive(:to_json).and_return(val)

        string = "hi"

        args = {
          not_a_string => not_a_string,
          string => string
        }

        result = Bear.encode_params(args)
        result.split('&').find do |key_and_val|
          key_and_val.match("#{not_a_string}=#{val}")
        end.should be_true
      end

      it "should escape all values" do
        args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

        result = Bear.encode_params(args)
        result.split('&').each do |key_val|
          key, val = key_val.split('=')
          val.should == CGI.escape(args[key])
        end
      end

      it "should convert all keys to Strings" do
        args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

        result = Bear.encode_params(args)
        result.split('&').each do |key_val|
          key, val = key_val.split('=')
          key.should == args.find{|key_val_arr| key_val_arr.last == val}.first.to_s
        end
      end
    end
  end
end