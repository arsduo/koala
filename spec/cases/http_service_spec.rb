require 'spec_helper'

describe Koala::HTTPService do
  it "has a faraday_middleware accessor" do
    expect(Koala::HTTPService.methods.map(&:to_sym)).to include(:faraday_middleware)
    expect(Koala::HTTPService.methods.map(&:to_sym)).to include(:faraday_middleware=)
  end

  it "has an http_options accessor" do
    expect(Koala::HTTPService).to respond_to(:http_options)
    expect(Koala::HTTPService).to respond_to(:http_options=)
  end

  it "sets http_options to {} by default" do
    expect(Koala::HTTPService.http_options).to eq({})
  end

  describe "DEFAULT_MIDDLEWARE" do
    before :each do
      @builder = double("Faraday connection builder")
      allow(@builder).to receive(:request)
      allow(@builder).to receive(:adapter)
      allow(@builder).to receive(:use)
    end

    it "is defined" do
      expect(Koala::HTTPService.const_defined?("DEFAULT_MIDDLEWARE")).to be_truthy
    end

    it "adds multipart" do
      expect(@builder).to receive(:use).with(Koala::HTTPService::MultipartRequest)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end

    it "adds url_encoded" do
      expect(@builder).to receive(:request).with(:url_encoded)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end

    it "uses the default adapter" do
      adapter = :testing_now
      allow(Faraday).to receive(:default_adapter).and_return(adapter)
      expect(@builder).to receive(:adapter).with(adapter)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end
  end

  describe Koala::HTTPService::DEFAULT_SERVERS do
    let(:defaults) { Koala::HTTPService::DEFAULT_SERVERS }

    it "defines the graph server" do
      expect(defaults[:graph_server]).to eq("graph.facebook.com")
    end

    it "defines the rest server" do
      expect(defaults[:rest_server]).to eq("api.facebook.com")
    end

    it "defines the dialog host" do
      expect(defaults[:dialog_host]).to eq("www.facebook.com")
    end

    it "defines the path replacement regular expression" do
      expect(defaults[:host_path_matcher]).to eq(/\.facebook/)
    end

    it "defines the video server replacement for uploads" do
      expect(defaults[:video_replace]).to eq("-video.facebook")
    end

    it "defines the beta tier replacement" do
      expect(defaults[:beta_replace]).to eq(".beta.facebook")
    end
  end

  describe "server" do
    describe "with no options" do
      it "returns the REST server if options[:rest_api]" do
        expect(Koala::HTTPService.server(:rest_api => true)).to eq(
         "http://#{Koala.config.rest_server}"
        )
      end

      it "returns the graph server if !options[:rest_api]" do
        expect(Koala::HTTPService.server(:rest_api => false)).to eq(
          "http://#{Koala.config.graph_server}"
        )
        expect(Koala::HTTPService.server({})).to eq(
          "http://#{Koala.config.graph_server}"
        )
      end

      context "with use_ssl" do
        it "includes https" do
          expect(Koala::HTTPService.server(use_ssl: true)).to eq(
            "https://#{Koala.config.graph_server}"
          )
        end
      end
    end

    describe "with options[:beta]" do
      before :each do
        @options = {:beta => true}
      end

      it "returns the beta REST server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        expect(server).to match(Regexp.new(Koala.config.rest_server.gsub(/\.facebook/, ".beta.facebook")))
      end

      it "returns the beta rest server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        expect(server).to match(Regexp.new(Koala.config.graph_server.gsub(/\.facebook/, ".beta.facebook")))
      end
    end

    describe "with options[:video]" do
      before :each do
        @options = {:video => true}
      end

      it "returns the REST video server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        expect(server).to match(Regexp.new(Koala.config.rest_server.gsub(/\.facebook/, "-video.facebook")))
      end

      it "returns the graph video server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        expect(server).to match(Regexp.new(Koala.config.graph_server.gsub(/\.facebook/, "-video.facebook")))
      end
    end
  end

  describe ".encode_params" do
    it "returns an empty string if param_hash evaluates to false" do
      expect(Koala::HTTPService.encode_params(nil)).to eq('')
    end

    it "converts values to JSON if the value is not a String" do
      val = 'json_value'
      not_a_string = 'not_a_string'
      allow(not_a_string).to receive(:is_a?).and_return(false)
      expect(MultiJson).to receive(:dump).with(not_a_string).and_return(val)

      string = "hi"

      args = {
        not_a_string => not_a_string,
        string => string
      }

      result = Koala::HTTPService.encode_params(args)
      expect(result.split('&').find do |key_and_val|
        key_and_val.match("#{not_a_string}=#{val}")
      end).to be_truthy
    end

    it "escapes all values" do
      args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        expect(val).to eq(CGI.escape(args[key]))
      end
    end

    it "encodes parameters in alphabetical order" do
      args = {:b => '2', 'a' => '1'}

      result = Koala::HTTPService.encode_params(args)
      expect(result.split('&').map{|key_val| key_val.split('=')[0]}).to eq(['a', 'b'])
    end

    it "converts all keys to Strings" do
      args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        expect(key).to eq(args.find{|key_val_arr| key_val_arr.last == val}.first.to_s)
      end
    end
  end

  describe ".make_request" do
    before :each do
      # Setup stubs for make_request to execute without exceptions
      @mock_body = double('Typhoeus response body')
      @mock_headers_hash = double({:value => "headers hash"})
      @mock_http_response = double("Faraday Response", :status => 200, :headers => @mock_headers_hash, :body => @mock_body)

      @mock_connection = double("Faraday connection")
      allow(@mock_connection).to receive(:get).and_return(@mock_http_response)
      allow(@mock_connection).to receive(:post).and_return(@mock_http_response)
      allow(Faraday).to receive(:new).and_return(@mock_connection)
    end

    describe "creating the Faraday connection" do
      it "creates a Faraday connection using the server" do
        server = "foo"
        allow(Koala::HTTPService).to receive(:server).and_return(server)
        expect(Faraday).to receive(:new).with(server, anything).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "anything")
      end

      it "merges Koala::HTTPService.http_options into the request params" do
        http_options = {:proxy => "http://user:password@example.org/", :request => { :timeout => 3 }}
        Koala::HTTPService.http_options = http_options
        expect(Faraday).to receive(:new).with(anything, hash_including(http_options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "does not merge invalid Faraday options from Koala::HTTPService.http_options into the request params" do
        http_options = {:invalid => "fake param"}
        Koala::HTTPService.http_options = http_options
        expect(Faraday).to receive(:new).with(anything, hash_not_including(http_options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "merges any provided options into the request params" do
        options = {:proxy => "http://user:password@example.org/", :request => { :timeout => 3 }}
        expect(Faraday).to receive(:new).with(anything, hash_including(options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "overrides Koala::HTTPService.http_options with any provided options for the request params" do
        options = {:proxy => "http://user:password@proxy.org/", :request => { :timeout => 10 }}
        http_options = {:proxy => "http://user:password@example.org/", :request => { :timeout => 3 }}
        allow(Koala::HTTPService).to receive(:http_options).and_return(http_options)

        expect(Faraday).to receive(:new).with(anything, hash_including(http_options.merge(options))).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "forces use_ssl to true if an access token is present" do
        options = {:use_ssl => false}
        allow(Koala::HTTPService).to receive(:http_options).and_return(:use_ssl => false)
        expect(Faraday).to receive(:new).with(anything, hash_including(:ssl => {:verify => true})).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get", options)
      end

      it "defaults verify to true if use_ssl is true" do
        expect(Faraday).to receive(:new).with(anything, hash_including(:ssl => {:verify => true})).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get")
      end

      it "allows you to set other verify modes if you really want" do
        options = {:ssl => {:verify => :foo}}
        expect(Faraday).to receive(:new).with(anything, hash_including(options)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {"access_token" => "foo"}, "get", options)
      end

      it "calls server with the composite options" do
        options = {:a => 2, :c => "3"}
        http_options = {:a => :a}
        allow(Koala::HTTPService).to receive(:http_options).and_return(http_options)
        expect(Koala::HTTPService).to receive(:server).with(hash_including(http_options.merge(options))).and_return("foo")
        Koala::HTTPService.make_request("anything", {}, "get", options)
      end

      it "uses the default builder block if HTTPService.faraday_middleware block is not defined" do
        block = Proc.new {}
        stub_const("Koala::HTTPService::DEFAULT_MIDDLEWARE", block)
        allow(Koala::HTTPService).to receive(:faraday_middleware).and_return(nil)
        expect(Faraday).to receive(:new).with(anything, anything, &block).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "uses the defined HTTPService.faraday_middleware block if defined" do
        block = Proc.new { }
        expect(Koala::HTTPService).to receive(:faraday_middleware).and_return(block)
        expect(Faraday).to receive(:new).with(anything, anything, &block).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", {}, "get")
      end
    end


    context "with API versions" do
      it "adds a version if specified by Koala.config" do
        expect(Koala.config).to receive(:api_version).and_return("v11")
        expect(@mock_connection).to receive(:get).with("/v11/anything", anything)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "prefers a version set in http_options" do
        allow(Koala.config).to receive(:api_version).and_return("v11")
        allow(Koala::HTTPService).to receive(:http_options).and_return({ api_version: 'v12' })
        expect(@mock_connection).to receive(:get).with("/v12/anything", anything)
        Koala::HTTPService.make_request("anything", {}, "get")
      end

      it "doesn't add double slashes to the path" do
        allow(Koala::HTTPService).to receive(:http_options).and_return({ api_version: 'v12' })
        expect(@mock_connection).to receive(:get).with("/v12/anything", anything)
        Koala::HTTPService.make_request("/anything", {}, "get")
      end

      it "doesn't add a version if the path already contains one" do
        expect(Koala.config).to receive(:api_version).and_return("v11")
        expect(@mock_connection).to receive(:get).with("/v12/anything", anything)
        Koala::HTTPService.make_request("/v12/anything", {}, "get")
      end
    end

    it "makes a POST request if the verb isn't get" do
      expect(@mock_connection).to receive(:post).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, "anything")
    end

    it "includes the verb in the body if the verb isn't get" do
      verb = "eat"
      expect(@mock_connection).to receive(:post).with(anything, hash_including("method" => verb)).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, verb)
    end

    it "makes a GET request if the verb is get" do
      expect(@mock_connection).to receive(:get).and_return(@mock_http_response)
      Koala::HTTPService.make_request("anything", {}, "get")
    end

    describe "for GETs" do
      it "submits the arguments in the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        expect(Faraday).to receive(:new).with(anything, hash_including(:params => args)).and_return(@mock_connection)
        Koala::HTTPService.make_request("anything", args, "get")
      end

      it "submits nothing to the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        expect(@mock_connection).to receive(:get).with(anything, {}).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", args, "get")
      end

      it "logs verb, url and params to debug" do
        args = {"a" => :b, "c" => 3}
        log_message_stem = "GET: anything params: "
        expect(Koala::Utils.logger).to receive(:debug) do |log_message|
          # unordered hashes are a bane
          # Ruby in 1.8 modes tends to return different hash orderings,
          # which makes checking the content of the stringified hash hard
          # it's enough just to ensure that there's hash content in the string, I think
          expect(log_message).to include(log_message_stem)
          expect(log_message.match(/\{.*\}/)).not_to be_nil
        end

        Koala::HTTPService.make_request("anything", args, "get")
      end
    end

    describe "for POSTs" do
      it "submits the arguments in the body" do
        # technically this is done for all requests, but you don't send GET requests with files
        args = {"a" => :b, "c" => 3}
        expect(@mock_connection).to receive(:post).with(anything, hash_including(args)).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", args, "post")
      end

      it "turns any UploadableIOs to UploadIOs" do
        # technically this is done for all requests, but you don't send GET requests with files
        upload_io = double("UploadIO")
        u = Koala::UploadableIO.new("/path/to/stuff", "img/jpg")
        allow(u).to receive(:to_upload_io).and_return(upload_io)
        expect(@mock_connection).to receive(:post).with(anything, hash_including("source" => upload_io)).and_return(@mock_http_response)
        Koala::HTTPService.make_request("anything", {:source => u}, "post")
      end

      it "logs verb, url and params to debug" do
        args = {"a" => :b, "c" => 3}
        log_message_stem = "POST: anything params: "
        expect(Koala::Utils.logger).to receive(:debug) do |log_message|
          # unordered hashes are a bane
          # Ruby in 1.8 modes tends to return different hash orderings,
          # which makes checking the content of the stringified hash hard
          # it's enough just to ensure that there's hash content in the string, I think
          expect(log_message).to include(log_message_stem)
          expect(log_message.match(/\{.*\}/)).not_to be_nil
        end
        Koala::HTTPService.make_request("anything", args, "post")
      end
    end
  end

  describe ".path_contains_api_version?" do
    it "works when the path is prefixed by a slash" do
      expect(Koala::HTTPService.path_contains_api_version?('/v2.1/anything')).to be true
    end

    it "works when the path is not prefixed by a slash" do
      expect(Koala::HTTPService.path_contains_api_version?('v2.1/anything')).to be true
    end

    it "works with versions without a ." do
      expect(Koala::HTTPService.path_contains_api_version?('v21/anything')).to be true
    end

    it "returns nil for paths without a version" do
      expect(Koala::HTTPService.path_contains_api_version?('/anything')).to be false
    end
  end
end
