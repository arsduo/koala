require 'koala/http_services'
class NetHTTPServiceTests < Test::Unit::TestCase
  module Bear
    include Koala::NetHTTPService
  end

  describe "NetHTTPService module holder class Bear" do
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

      describe "the connection" do
        it "should use POST if verb is not GET" do
          @http_yield_mock.should_receive(:post).and_return(@mock_http_response)
          @http_mock.should_receive(:start).and_yield(@http_yield_mock)

          Bear.make_request('anything', {}, 'anything')
        end

        it "should use GET if that verb is specified" do
          @http_yield_mock.should_receive(:get).and_return(@mock_http_response)
          @http_mock.should_receive(:start).and_yield(@http_yield_mock)

          Bear.make_request('anything', {}, 'get')
        end

        it "should add the method to the arguments if it's not get or post" do
          args = {}
          method = "telekenesis"
          # since the arguments get encoded later, we'll test for merge!
          # even though that's somewhat testing internal implementation
          args.should_receive(:merge!).with(:method => method)

          Bear.make_request('anything', args, method)
        end
      end

      describe "if the request has an access token" do
        before :each do
          @args = {"access_token" => "123"}
        end

        it "should use SSL" do
          @http_mock.should_receive('use_ssl=').with(true)

          Bear.make_request('anything', @args, 'anything')
        end

        it "should set the port to 443" do
          Net::HTTP.should_receive(:new).with(anything, 443).and_return(@http_mock)

          Bear.make_request('anything', @args, 'anything')
        end
      end

      describe "if always_use_ssl is true" do
        before :each do
          Bear.always_use_ssl = true
        end

        it "should use SSL" do
          @http_mock.should_receive('use_ssl=').with(true)

          Bear.make_request('anything', {}, 'anything')
        end

        it "should set the port to 443" do
          Net::HTTP.should_receive(:new).with(anything, 443).and_return(@http_mock)

          Bear.make_request('anything', {}, 'anything')
        end
      end

      describe "if the use_ssl option is provided" do
        it "should use SSL" do
          @http_mock.should_receive('use_ssl=').with(true)

          Bear.make_request('anything', {}, 'anything', :use_ssl => true)
        end

        it "should set the port to 443" do
          Net::HTTP.should_receive(:new).with(anything, 443).and_return(@http_mock)

          Bear.make_request('anything', {}, 'anything', :use_ssl => true)
        end
      end

      describe "if there's no token and always_use_ssl isn't true" do
        it "should not use SSL" do
          @http_mock.should_not_receive('use_ssl=')
          Bear.make_request('anything', {}, 'anything')
        end

        it "should not set the port" do
          Net::HTTP.should_receive(:new).with(anything, nil).and_return(@http_mock)
          Bear.make_request('anything', {}, 'anything')
        end
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

        describe "with multipart/form-data" do
          before(:each) do
            Bear.stub(:encode_multipart_params)
            Bear.stub("params_require_multipart?").and_return(true)

            @multipart_request_stub = stub('Stub Multipart Request')
            Net::HTTP::Post::Multipart.stub(:new).and_return(@multipart_request_stub)

            @file_stub = stub('fake File', "kind_of?" => true, "path" => 'anypath.jpg')

            @http_yield_mock.stub(:request).with(@multipart_request_stub).and_return(@http_request_result)
          end

          it "should use multipart/form-data if any parameter is a valid file hash" do
            @http_yield_mock.should_receive(:request).with(@multipart_request_stub).and_return(@http_request_result)

            Bear.make_request('anything', {}, 'post')
          end

          it "should use the given request path for the request" do
            args = {"file" => @file_stub}
            expected_path = 'expected/path'

            Net::HTTP::Post::Multipart.should_receive(:new).with(expected_path, anything).and_return(@multipart_request_stub)

            Bear.make_request(expected_path, {}, 'post')
          end

          it "should use multipart encoded arguments for the request" do
            args = {"file" => @file_stub}
            expected_params = stub('Stub Multipart Params')

            Bear.should_receive(:encode_multipart_params).with(args).and_return(expected_params)
            Net::HTTP::Post::Multipart.should_receive(:new).with(anything, expected_params).and_return(@multipart_request_stub)

            Bear.make_request('anything', args, 'post')
          end
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

    describe "when detecting if multipart posting is needed" do
      it "should be true if any parameter value requires multipart post" do
        valid_file_hash = stub("Stub Valid File Hash")

        Bear.stub!("is_valid_file_hash?").and_return(false)
        Bear.stub!("is_valid_file_hash?").with(valid_file_hash).and_return(true)

        args = {
          "key1" => "val",
          "key2" => "val",
          "key3" => valid_file_hash,
          "key4" => "val"
        }

        Bear.params_require_multipart?(args).should be_true
      end

      # we need to test against both :symbols and "strings"
      # so we run it twice, with 
      shared_examples_for "file values" do
        it "should only accept hashes" do
          Bear.is_valid_file_hash?(@valid_hash).should be_true

          @valid_hash.stub!("kind_of?").with(Hash).and_return(false)
          Bear.is_valid_file_hash?(@valid_hash).should be_false
        end

        it "should always require a content_type key" do
          @valid_hash.delete("content_type".send(@key_method))
          Bear.is_valid_file_hash?(@valid_hash).should be_false
        end

        it "should always require the path key" do
          @valid_hash.delete("path".send(@key_method))
          Bear.is_valid_file_hash?(@valid_hash).should be_false
        end

        describe "with file IOs" do
          before :each do
            @stub_file = stub('Stub IO File')
            @valid_hash["file".send(@key_method)] = @stub_file
          end

          it "should accept hashes with the file object that responds to read" do
            @stub_file.should_receive("respond_to?").with(:read).and_return(true)
            @valid_hash["file".send(@key_method)] = @stub_file
            Bear.is_valid_file_hash?(@valid_hash).should be_true
          end

          it "should not accept hashes with a file object that does not respond to read" do
            @stub_file.should_receive("respond_to?").with(:read).and_return(false)
            @valid_hash["file".send(@key_method)] = @stub_file
            Bear.is_valid_file_hash?(@valid_hash).should be_false
          end
        end
      end

      describe "and looking at individual values with strings" do
        before(:each) do          
          @valid_hash = {
            "content_type" => 1,
            "path" => 1
          }
          @key_method = "to_s"
        end
        
        it_should_behave_like "file values"
      end
        
      describe "and looking at individual values" do
        before(:each) do          
          @valid_hash = {
            :content_type => 1,
            :path => 1
          }
          @key_method = "to_sym"
        end
        
        it_should_behave_like "file values"
      end

      shared_examples_for "encoding multipart data" do
        it "should replace valid file hashes with file objects with UploadIO objects" do
          path_key = "path".send(@key_method)
          content_type_key = "content_type".send(@key_method)
          file_hash_stub = {
             path_key => "Fake File Name",
             content_type_key => "Fake Content Type"
          }
          # UploadIO should be created
          uploadio_stub = stub("UploadIO Shell Stub")
          UploadIO.should_receive("new").with(file_hash_stub[path_key], file_hash_stub[content_type_key]).and_return(uploadio_stub)

          # Ruby 1.9 test compatibility
          content_stub = "UploadIOContent Stub"
          uploadio_stub.stub(:to_ary).and_return([content_stub])

          args = {
            "not_a_file" => "not a file",
            "file" => file_hash_stub
          }

          # Check that is_valid_file_hash is called on the file_hash_stub
          Bear.stub!("is_valid_file_hash?").and_return(false)
          Bear.should_receive("is_valid_file_hash?").with(file_hash_stub).and_return(true)

          result = Bear.encode_multipart_params(args)

          result["not_a_file"] == args["not_a_file"]
          result["file"] == content_stub
        end

        it "should replace valid file hashes with file objects with UploadIO objects" do
          file_key = "file".send(@key_method)
          path_key = "path".send(@key_method)
          content_type_key = "content_type".send(@key_method)
          file_hash_stub = {
             file_key => "Fake File IO",
             path_key => "Fake File Name",
             content_type_key => "Fake Content Type"
          }

          # UploadIO should be created
          uploadio_stub = stub("UploadIO Shell Stub")
          UploadIO.should_receive("new").with(file_hash_stub[file_key], file_hash_stub[content_type_key], file_hash_stub[path_key]).and_return(uploadio_stub)

          # Ruby 1.9 test compatibility
          content_stub = "UploadIOContent Stub"
          uploadio_stub.stub(:to_ary).and_return([content_stub])

          args = {
            "not_a_file" => "not a file",
            "file" => file_hash_stub
          }

          # Check that is_valid_file_hash is called on the file_hash_stub
          Bear.stub!("is_valid_file_hash?").and_return(false)
          Bear.should_receive("is_valid_file_hash?").with(file_hash_stub).and_return(true)

          result = Bear.encode_multipart_params(args)

          result["not_a_file"] == args["not_a_file"]
          result["file"] == content_stub
        end
      end
      
      describe "when encoding multipart/form-data params that are strings" do
        before :each do
          @key_method = "to_s"
        end
        
        it_should_behave_like "encoding multipart data"
      end
      
      describe "when encoding multipart/form-data params that are strings" do
        before :each do 
          @key_method = "to_sym"
        end
        
        it_should_behave_like "encoding multipart data"
      end
      
    end
  end
end