require 'spec_helper'

describe "Koala::HTTPService" do
  it "has a faraday_middleware accessor" do
    Koala::HTTPService.methods.map(&:to_sym).should include(:faraday_middleware)
    Koala::HTTPService.methods.map(&:to_sym).should include(:faraday_middleware=)
  end

  it "has an http_options accessor" do
    Koala::HTTPService.should respond_to(:http_options)
    Koala::HTTPService.should respond_to(:http_options=)
  end

  it "sets http_options to {} by default" do
    Koala::HTTPService.http_options.should == {}
  end

  describe "DEFAULT_MIDDLEWARE" do
    before :each do
      @builder = stub("Faraday connection builder")
      @builder.stub(:request)
      @builder.stub(:adapter)
      @builder.stub(:use)
    end

    it "is defined" do
      Koala::HTTPService.const_defined?("DEFAULT_MIDDLEWARE").should be_true
    end

    it "adds multipart" do
      @builder.should_receive(:use).with(Koala::HTTPService::MultipartRequest)
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
        server.should =~ Regexp.new(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, ".beta.facebook"))
      end

      it "returns the beta rest server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER.gsub(/\.facebook/, ".beta.facebook"))
      end
    end

    describe "with options[:video]" do
      before :each do
        @options = {:video => true}
      end

      it "returns the REST video server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        server.should =~ Regexp.new(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end

      it "returns the graph video server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end
    end
  end

  describe ".encode_params" do
    it "returns an empty string if param_hash evaluates to false" do
      Koala::HTTPService.encode_params(nil).should == ''
    end

    it "converts values to JSON if the value is not a String" do
      val = 'json_value'
      not_a_string = 'not_a_string'
      not_a_string.stub(:is_a?).and_return(false)
      MultiJson.should_receive(:dump).with(not_a_string).and_return(val)

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

    it "escapes all values" do
      args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        val.should == CGI.escape(args[key])
      end
    end

    it "encodes parameters in alphabetical order" do
      args = {:b => '2', 'a' => '1'}

      result = Koala::HTTPService.encode_params(args)
      result.split('&').map{|key_val| key_val.split('=')[0]}.should == ['a', 'b']
    end

    it "converts all keys to Strings" do
      args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        key.should == args.find{|key_val_arr| key_val_arr.last == val}.first.to_s
      end
    end
  end

  describe ".make_request" do
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

      it "merges Koala::HTTPService.http_options into the request params" do
        http_options = {:a => 2, :c => "3"}
        Koala::HTTPService.http_options = http_options
        Faraday.should_receive(:new).with(anything, hash_including(http_options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "merges any provided options into the request params" do
        options = {:a => 2, :c => "3"}
        Faraday.should_receive(:new).with(anything, hash_including(options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "overrides Koala::HTTPService.http_options with any provided options for the request params" do
        options = {:a => 2, :c => "3"}
        http_options = {:a => :a}
        Koala::HTTPService.stub(:http_options).and_return(http_options)

        Faraday.should_receive(:new).with(anything, hash_including(http_options.merge(options))).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "forces use_ssl to true if an access token is present" do
        options = {:use_ssl => false}
        Koala::HTTPService.stub(:http_options).and_return(:use_ssl => false)
        Faraday.should_receive(:new).with(anything, hash_including(:use_ssl => true, :ssl => {:verify => true})).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get", options)
      end

      it "defaults verify to true if use_ssl is true" do
        Faraday.should_receive(:new).with(anything, hash_including(:ssl => {:verify => true})).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get")
      end

      it "allows you to set other verify modes if you really want" do
        options = {:ssl => {:verify => :foo}}
        Faraday.should_receive(:new).with(anything, hash_including(options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get", options)
      end

      it "calls server with the composite options" do
        options = {:a => 2, :c => "3"}
        http_options = {:a => :a}
        Koala::HTTPService.stub(:http_options).and_return(http_options)
        Koala::HTTPService.should_receive(:server).with(hash_including(http_options.merge(options))).and_return("foo")
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "uses the default builder block if HTTPService.faraday_middleware block is not defined" do
        Koala::HTTPService.stub(:faraday_middleware).and_return(nil)
        Faraday.should_receive(:new).with(anything, anything, &Koala::HTTPService::DEFAULT_MIDDLEWARE).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "uses the defined HTTPService.faraday_middleware block if defined" do
        block = Proc.new { }
        Koala::HTTPService.should_receive(:faraday_middleware).and_return(block)
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

      it "logs verb, url and params to debug" do
        args = {"a" => :b, "c" => 3}
        log_message_stem = "GET: anything params: "
        Koala::Utils.logger.should_receive(:debug) do |log_message|
          # unordered hashes are a bane
          # Ruby in 1.8 modes tends to return different hash orderings,
          # which makes checking the content of the stringified hash hard
          # it's enough just to ensure that there's hash content in the string, I think
          log_message.should include(log_message_stem)
          log_message.match(/\{.*\}/).should_not be_nil
        end

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

      it "logs verb, url and params to debug" do
        args = {"a" => :b, "c" => 3}
        log_message_stem = "POST: anything params: "
        Koala::Utils.logger.should_receive(:debug) do |log_message|
          # unordered hashes are a bane
          # Ruby in 1.8 modes tends to return different hash orderings,
          # which makes checking the content of the stringified hash hard
          # it's enough just to ensure that there's hash content in the string, I think
          log_message.should include(log_message_stem)
          log_message.match(/\{.*\}/).should_not be_nil
        end
        Koala::HTTPService.make_request("anything", args, "post")
      end
    end
  end

  describe "deprecated options" do
    before :each do
      Koala::HTTPService.stub(:http_options).and_return({})
      @service = Koala.http_service
    end

    after :each do
      Koala.http_service = @service
    end

    {
      :timeout => :timeout,
      :always_use_ssl => :use_ssl,
      :proxy => :proxy
    }.each_pair do |deprecated_method, parameter|
      describe ".#{deprecated_method}" do
        context "read" do
          it "reads http_options[:#{parameter}]" do
            value = "foo"
            Koala::HTTPService.http_options[parameter] = value
            Koala::HTTPService.send(deprecated_method).should == value
          end

          it "generates a deprecation warning" do
            Koala::Utils.should_receive(:deprecate)
            Koala::HTTPService.send(deprecated_method)
          end
        end

        context "write" do
          it "writes to http_options[:#{parameter}]" do
            Koala::HTTPService.http_options[parameter] = nil
            value = "foo"
            Koala::HTTPService.send(:"#{deprecated_method}=", value)
            Koala::HTTPService.http_options[parameter].should == value
          end

          it "generates a deprecation warning" do
            Koala::Utils.should_receive(:deprecate)
            Koala::HTTPService.send(:"#{deprecated_method}=", 2)
          end
        end
      end
    end

    # ssl options
    [:ca_path, :ca_file, :verify_mode].each do |deprecated_method|
      describe ".#{deprecated_method}" do
        context "read" do
          it "reads http_options[:ssl][:#{deprecated_method}] if http_options[:ssl]" do
            value = "foo"
            Koala::HTTPService.http_options[:ssl] = {deprecated_method => value}
            Koala::HTTPService.send(deprecated_method).should == value
          end

          it "returns nil if http_options[:ssl] is not defined" do
            Koala::HTTPService.send(deprecated_method).should be_nil
          end

          it "generates a deprecation warning" do
            Koala::Utils.should_receive(:deprecate)
            Koala::HTTPService.send(deprecated_method)
          end
        end

        context "write" do
          it "defines http_options[:ssl] if not defined" do
            Koala::HTTPService.http_options[:ssl] = nil
            value = "foo"
            Koala::HTTPService.send(:"#{deprecated_method}=", value)
            Koala::HTTPService.http_options[:ssl].should
          end

          it "writes to http_options[:ssl][:#{deprecated_method}]" do
            value = "foo"
            Koala::HTTPService.send(:"#{deprecated_method}=", value)
            Koala::HTTPService.http_options[:ssl].should
            Koala::HTTPService.http_options[:ssl][deprecated_method].should == value
          end

          it "does not redefine http_options[:ssl] if already defined" do
            hash = {:a => 2}
            Koala::HTTPService.http_options[:ssl] = hash
            Koala::HTTPService.send(:"#{deprecated_method}=", 3)
            Koala::HTTPService.http_options[:ssl].should include(hash)
          end

          it "generates a deprecation warning" do
            Koala::Utils.should_receive(:deprecate)
            Koala::HTTPService.send(:"#{deprecated_method}=", 2)
          end
        end
      end
    end

    describe "per-request options" do
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

      describe ":typhoeus_options" do
        it "merges any typhoeus_options into options" do
          typhoeus_options = {:a => 2}
          Faraday.should_receive(:new).with(anything, hash_including(typhoeus_options)).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :typhoeus_options => typhoeus_options)
        end

        it "deletes the typhoeus_options key" do
          typhoeus_options = {:a => 2}
          Faraday.should_receive(:new).with(anything, hash_not_including(:typhoeus_options => typhoeus_options)).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :typhoeus_options => typhoeus_options)
        end
      end

      describe ":ca_path" do
        it "sets any ca_path into options[:ssl]" do
          ca_path = :foo
          Faraday.should_receive(:new).with(anything, hash_including(:ssl => hash_including(:ca_path => ca_path))).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :ca_path => ca_path)
        end

        it "deletes the ca_path key" do
          ca_path = :foo
          Faraday.should_receive(:new).with(anything, hash_not_including(:ca_path => ca_path)).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :ca_path => ca_path)
        end
      end

      describe ":ca_file" do
        it "sets any ca_file into options[:ssl]" do
          ca_file = :foo
          Faraday.should_receive(:new).with(anything, hash_including(:ssl => hash_including(:ca_file => ca_file))).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :ca_file => ca_file)
        end

        it "deletes the ca_file key" do
          ca_file = :foo
          Faraday.should_receive(:new).with(anything, hash_not_including(:ca_file => ca_file)).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :ca_file => ca_file)
        end
      end

      describe ":verify_mode" do
        it "sets any verify_mode into options[:ssl]" do
          verify_mode = :foo
          Faraday.should_receive(:new).with(anything, hash_including(:ssl => hash_including(:verify_mode => verify_mode))).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :verify_mode => verify_mode)
        end

        it "deletes the verify_mode key" do
          verify_mode = :foo
          Faraday.should_receive(:new).with(anything, hash_not_including(:verify_mode => verify_mode)).and_return(@mock_connection)
          Koala::HTTPService.make_request("anything", {}, "get", :verify_mode => verify_mode)
        end
      end
    end
  end
end
