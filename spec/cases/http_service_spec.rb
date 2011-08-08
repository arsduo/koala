require 'spec_helper'


describe "Koala::HTTPService" do
  describe "faraday_configuration accessor" do
    it "exists" do
      # in Ruby 1.8, .methods returns strings
      # in Ruby 1.9, .method returns symbols
      Koala::HTTPService.methods.map(&:to_sym).should include(:faraday_configuration)
      Koala::HTTPService.methods.map(&:to_sym).should include(:faraday_configuration=)
    end
  end

  describe "DEFAULT_MIDDLEWARE" do
    before :each do
      @builder = stub("Faraday connection builder")
      @builder.stub(:request)
      @builder.stub(:adapter)
    end

    it "is defined" do
      Koala::HTTPService.const_defined?("DEFAULT_MIDDLEWARE").should be_true
    end

    it "adds multipart" do
      @builder.should_receive(:request).with(:multipart)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end

    it "adds url_encoded" do
      @builder.should_receive(:request).with(:url_encoded)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end

    it "uses the default adapter" do
      adapter = :testing_now
      Faraday.stub(:default_adapter).and_return(adapter)
      @builder.should_receive(:adapter).with(adapter)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end
  end

  describe "server" do
    describe "with no options" do
      it "returns the REST server if options[:rest_api]" do
        Koala::HTTPService.server(:rest_api => true).should =~ Regexp.new(Koala::Facebook::REST_SERVER)
      end

      it "returns the graph server if !options[:rest_api]" do
        Koala::HTTPService.server(:rest_api => false).should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER)
        Koala::HTTPService.server({}).should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER)
      end
    end

    describe "with options[:beta]" do
      before :each do
        @options = {:beta => true}
      end

      it "returns the beta REST server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        server.should =~ Regexp.new("beta.#{Koala::Facebook::REST_SERVER}")
      end

      it "returns the beta rest server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new("beta.#{Koala::Facebook::GRAPH_SERVER}")
      end
    end

    describe "with options[:video]" do
      before :each do
        @options = {:video => true}
      end

      it "should return the REST video server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        server.should =~ Regexp.new(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end

      it "should return the graph video server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end
    end
  end

  describe "#encode_params" do
    it "should return an empty string if param_hash evaluates to false" do
      Koala::HTTPService.encode_params(nil).should == ''
    end

    it "should convert values to JSON if the value is not a String" do
      val = 'json_value'
      not_a_string = 'not_a_string'
      not_a_string.stub(:is_a?).and_return(false)
      MultiJson.should_receive(:encode).with(not_a_string).and_return(val)

      string = "hi"

      args = {
        not_a_string => not_a_string,
        string => string
      }

      result = Koala::HTTPService.encode_params(args)
      result.split('&').find do |key_and_val|
        key_and_val.match("#{not_a_string}=#{val}")
      end.should be_true
    end

    it "should escape all values" do
      args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        val.should == CGI.escape(args[key])
      end
    end

    it "should convert all keys to Strings" do
      args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        key.should == args.find{|key_val_arr| key_val_arr.last == val}.first.to_s
      end
    end
  end

  describe "#make_request" do
    before :each do
      # Setup stubs for make_request to execute without exceptions
      @mock_body = stub('Typhoeus response body')
      @mock_headers_hash = stub({:value => "headers hash"})
      @mock_http_response = stub("Faraday Response", :status => 200, :headers => @mock_headers_hash, :body => @mock_body)

      @mock_connection = stub("Faraday connection")
      @mock_connection.stub(:get).and_return(@mock_http_response)
      @mock_connection.stub(:post).and_return(@mock_http_response)
      Faraday.stub(:new).and_return(@mock_connection)
    end

    describe "creating the Faraday connection" do
      it "creates a Faraday connection using the server" do
        server = "foo"
        Koala::HTTPService.stub(:server).and_return(server)
        Faraday.should_receive(:new).with(server, anything).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "anything")
      end

      it "merges Koala.http_options into the request params" do
        http_options = {:a => 2, :c => "3"}
        Koala.stub(:http_options).and_return(http_options)
        Faraday.should_receive(:new).with(anything, hash_including(http_options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "merges any provided options into the request params" do
        options = {:a => 2, :c => "3"}
        Faraday.should_receive(:new).with(anything, hash_including(options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "overrides Koala.http_options with any provided options for the request params" do
        options = {:a => 2, :c => "3"}
        http_options = {:a => :a}
        Koala.stub(:http_options).and_return(http_options)

        Faraday.should_receive(:new).with(anything, hash_including(http_options.merge(options))).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "uses the default builder block if HTTPService.faraday_configuration block is not defined" do
        Koala::HTTPService.stub(:faraday_configuration).and_return(nil)        
        Faraday.should_receive(:new).with(anything, anything, &Koala::HTTPService::DEFAULT_MIDDLEWARE).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")        
      end
      
      it "uses the defined HTTPService.faraday_configuration block if defined" do
        block = Proc.new { }
        Koala::HTTPService.should_receive(:faraday_configuration).and_return(block)
        Faraday.should_receive(:new).with(anything, anything, &block).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")        
      end
    end

    it "makes a POST request if the verb isn't get" do
      @mock_connection.should_receive(:post).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, "anything")
    end

    it "includes the verb in the body if the verb isn't get" do
      verb = "eat"
      @mock_connection.should_receive(:post).with(anything, hash_including("method" => verb)).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, verb)
    end

    it "makes a GET request if the verb is get" do
      @mock_connection.should_receive(:get).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, "get")
    end

    describe "for GETs" do
      it "submits the arguments in the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        Faraday.should_receive(:new).with(anything, hash_including(:params => args)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", args, "get")
      end

      it "submits nothing to the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        @mock_connection.should_receive(:get).with(anything, {}).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", args, "get")
      end
    end

    describe "for POSTs" do
      it "submits the arguments in the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        @mock_connection.should_receive(:post).with(anything, hash_including(args)).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", args, "post")
      end

      it "turns any UploadableIOs to UploadIOs" do
        # technically this is done for all requests, but you don't send GET requests with files
        upload_io = stub("UploadIO")
        u = Koala::UploadableIO.new("/path/to/stuff", "img/jpg")
        u.stub(:to_upload_io).and_return(upload_io)
        @mock_connection.should_receive(:post).with(anything, hash_including("source" => upload_io)).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", {:source => u}, "post")
      end
    end
  end
end
