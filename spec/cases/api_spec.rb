require 'spec_helper'

describe "Koala::Facebook::API" do
  before :each do
    @service = Koala::Facebook::API.new
  end
  let(:dummy_response) { double("fake response", data: {}, status: 200, body: "", headers: {}) }

  it "defaults to the globally configured token if one's provided" do
    token = "Foo"

    Koala.configure do |config|
      config.access_token = token
    end

    expect(Koala::Facebook::API.new.access_token).to eq(token)
  end

  it "defaults to the globally configured app_secret if one's provided" do
    app_secret = "Foo"

    Koala.configure do |config|
      config.app_secret = app_secret
    end

    expect(Koala::Facebook::API.new.app_secret).to eq(app_secret)
  end

  describe "client-specific configuration" do
    it "keeps the legacy three positional arguments and preserves explicit nils" do
      Koala.configure do |config|
        config.access_token = "global-token"
        config.app_secret = "global-secret"
        config.rate_limit_hook = :global_hook
      end

      api = Koala::Facebook::API.new(nil, nil, nil)
      expect(api.access_token).to be_nil
      expect(api.app_secret).to be_nil
      expect(api.rate_limit_hook).to be_nil
    end

    it "uses the supplied configuration as defaults without duplicating or mutating it" do
      config = Koala::Configuration.new
      config.access_token = "client-token"
      config.app_secret = "client-secret"
      config.rate_limit_hook = :client_hook
      original_values = [config.access_token, config.app_secret, config.rate_limit_hook]

      api = Koala::Facebook::API.new(config: config)

      expect([api.access_token, api.app_secret, api.rate_limit_hook]).to eq(original_values)
      expect(config).to have_attributes(access_token: "client-token", app_secret: "client-secret", rate_limit_hook: :client_hook)
    end

    it "keeps global request configuration live while capturing credential defaults at initialization" do
      Koala.configure do |config|
        config.access_token = "initial-token"
        config.graph_server = "initial.example.com"
      end
      api = Koala::Facebook::API.new

      Koala.configure do |config|
        config.access_token = "later-token"
        config.graph_server = "later.example.com"
      end

      expect(api.access_token).to eq("initial-token")
      requests = []
      service = Object.new
      service.define_singleton_method(:make_request) do |request|
        requests << request
        Koala::HTTPService::Response.new(200, "{}", {})
      end
      old_service = Koala.http_service
      Koala.http_service = service

      begin
        api.api("me")
      ensure
        Koala.http_service = old_service
      end

      expect(requests.last.server).to eq("https://later.example.com")
    end

    it "continues to use the live global configuration after reset_config" do
      api = Koala::Facebook::API.new
      Koala.reset_config
      Koala.config.graph_server = "reset.example.com"
      requests = []
      service = Object.new
      service.define_singleton_method(:make_request) do |request|
        requests << request
        Koala::HTTPService::Response.new(200, "{}", {})
      end
      old_service = Koala.http_service
      Koala.http_service = service

      begin
        api.api("me")
      ensure
        Koala.http_service = old_service
      end

      expect(requests.last.server).to eq("https://reset.example.com")
    end

    it "uses client-specific defaults for form arguments" do
      config = Koala::Configuration.new
      config.preserve_form_arguments = true
      api = Koala::Facebook::API.new(config: config)
      response = Koala::HTTPService::Response.new(200, "", {})
      expect(Koala).to receive(:make_request).with("/me", {"ids" => [1, 2]}, "get", {}, config).and_return(response)

      api.api("me", {"ids" => [1, 2]})
    end

    it "keeps explicit client configuration isolated across interleaved requests" do
      first_config = Koala.config.dup
      first_config.graph_server = "graph.instagram.com"
      second_config = Koala.config.dup
      second_config.graph_server = "graph.threads.net"
      requests = []
      service = Object.new
      service.define_singleton_method(:make_request) do |request|
        requests << request
        Koala::HTTPService::Response.new(200, "{}", {})
      end
      old_service = Koala.http_service
      Koala.http_service = service

      begin
        Koala::Facebook::API.new(config: first_config).api("me")
        Koala::Facebook::API.new(config: second_config).api("me")
      ensure
        Koala.http_service = old_service
      end

      expect(requests.map(&:server)).to eq(["https://graph.instagram.com", "https://graph.threads.net"])
      expect(requests.map(&:raw_options)).to eq([{}, {}])
    end

    it "keeps explicit client configuration isolated across concurrent requests" do
      configs = ["graph.instagram.com", "graph.threads.net"].map do |host|
        Koala.config.dup.tap { |config| config.graph_server = host }
      end
      servers = Queue.new
      service = Object.new
      service.define_singleton_method(:make_request) do |request|
        servers << request.server
        Koala::HTTPService::Response.new(200, "{}", {})
      end
      old_service = Koala.http_service
      Koala.http_service = service

      begin
        threads = configs.map do |config|
          Thread.new { Koala::Facebook::API.new(config: config).api("me") }
        end
        threads.each(&:value)
      ensure
        Koala.http_service = old_service
      end

      expect([servers.pop, servers.pop]).to match_array(["https://graph.instagram.com", "https://graph.threads.net"])
    end

    it "passes configuration through the existing one-request custom service contract" do
      config = Koala.config.dup
      config.graph_server = "graph.instagram.com"
      service = Object.new
      allow(service).to receive(:make_request) do |request|
        expect(request.configuration).to equal(config)
        Koala::HTTPService::Response.new(200, "{}", {})
      end
      old_service = Koala.http_service
      Koala.http_service = service

      begin
        Koala::Facebook::API.new(config: config).api("me")
      ensure
        Koala.http_service = old_service
      end
    end

    it "preserves appsecret proofs for clients with explicit configuration" do
      token = "client-token"
      secret = "client-secret"
      config = Koala::Configuration.new
      api = Koala::Facebook::API.new(token, secret, nil, config: config)
      expected_proof = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, token)
      response = Koala::HTTPService::Response.new(200, "", {})
      expect(Koala).to receive(:make_request).with("/me", hash_including("appsecret_proof" => expected_proof), "get", {}, config).and_return(response)

      api.api("me", {}, "get", appsecret_proof: true)
    end

    it "keeps configuration on pageable results and batch calls" do
      config = Koala.config.dup
      config.graph_server = "graph.instagram.com"
      config.access_token = "client-token"
      api = Koala::Facebook::API.new(config: config)
      collection = Koala::Facebook::API::GraphCollection.new(
        Koala::HTTPService::Response.new(200, {"data" => [], "paging" => {"next" => "https://example.com/v2/me?access_token=token"}}.to_json, {}),
        api
      )
      requests = []
      allow(Koala).to receive(:make_request) do |path, args, verb, options, request_config|
        requests << [path, args, verb, options, request_config]
        Koala::HTTPService::Response.new(200, '{"data":[]}', {})
      end

      collection.next_page
      api.batch { |batch| batch.get_object("me") }

      expect(requests.length).to eq(2)
      expect(requests.map(&:last)).to all(equal(config))
    end
  end

  it "doesn't include an access token if none was given" do
    expect(Koala).to receive(:make_request).with(
      anything,
      hash_not_including('access_token' => 1),
      anything,
      anything
    ).and_return(Koala::HTTPService::Response.new(200, "", ""))

    @service.api('anything')
  end

  it "includes an access token if given" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token

    expect(Koala).to receive(:make_request).with(
      anything,
      hash_including('access_token' => token),
      anything,
      anything
    ).and_return(Koala::HTTPService::Response.new(200, "", ""))

    service.api('anything')
  end

  it "doesn't add token to received arguments" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token

    expect(Koala).to receive(:make_request).with(
                       anything,
                       hash_including('access_token' => token),
                       anything,
                       anything
                     ).and_return(Koala::HTTPService::Response.new(200, "", ""))

    args = {}.freeze
    service.api('anything', args)
  end

  it "turns arrays of non-enumerables into comma-separated arguments by default" do
    args = [12345, {:foo => [1, 2, "3", :four]}]
    expected = ["/12345", {:foo => "1,2,3,four"}, "get", {}]
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    expect(Koala).to receive(:make_request).with(*expected).and_return(response)
    @service.api(*args)
  end

  it "can be configured to leave arrays of non-enumerables as is" do
    Koala.configure do |config|
      config.preserve_form_arguments = true
    end

    args = [12345, {:foo => [1, 2, "3", :four]}]
    expected = ["/12345", {:foo => [1, 2, "3", :four]}, "get", {}]
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    expect(Koala).to receive(:make_request).with(*expected).and_return(response)
    @service.api(*args)
  end

  it "can be configured on a per-request basis to leave arrays as is" do
    args = [12345, {foo: [1, 2, "3", :four]}, "get", preserve_form_arguments: true]
    expected = ["/12345", {foo: [1, 2, "3", :four]}, "get", preserve_form_arguments: true]
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    expect(Koala).to receive(:make_request).with(*expected).and_return(response)
    @service.api(*args)
  end

  it "doesn't turn arrays containing enumerables into comma-separated strings" do
    params = {:foo => [1, 2, ["3"], :four]}
    args = [12345, params]
    # we leave this as is -- the HTTP layer can either handle it appropriately
    # (if appropriate behavior is defined)
    # or raise an exception
    expected = ["/12345", params, "get", {}]
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    expect(Koala).to receive(:make_request).with(*expected).and_return(response)
    @service.api(*args)
  end

  it "doesn't modify any data if the option format of :json is provided" do
    args = [12345, {:foo => [1, 2, "3", :four]}, 'get', format: :json]
    expected = ["/12345", {:foo => [1, 2, "3", :four]}, 'get', format: :json]
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    expect(Koala).to receive(:make_request).with(*expected).and_return(response)
    @service.api(*args)
  end

  it "raises an API error if the HTTP response code is greater than or equal to 500" do
    allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(500, 'response body', {}))

    expect { @service.api('anything') }.to raise_exception(Koala::Facebook::APIError)
  end

  describe "path manipulation" do
    context "leading /" do
      it "adds a leading / to the path if not present" do
        path = "anything"
        expect(Koala).to receive(:make_request).with("/#{path}", anything, anything, anything).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
        @service.api(path)
      end

      it "doesn't change the path if a leading / is present" do
        path = "/anything"
        expect(Koala).to receive(:make_request).with(path, anything, anything, anything).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
        @service.api(path)
      end
    end
  end

  describe "with an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new(@token)
      @app_access_token = KoalaTest.app_access_token
    end

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  describe "without an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new
    end

    # In theory this should behave the same with a GraphCollection, but those tests currently hit
    # an endpoint that now requires a token.
    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
  end

  context '#api' do
    let(:access_token) { 'access_token' }
    let(:api) { Koala::Facebook::API.new(access_token) }
    let(:path) { '/path' }
    let(:appsecret) { 'appsecret' }
    let(:token_args) { { 'access_token' => access_token } }
    let(:appsecret_proof_args) { { 'appsecret_proof' => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), appsecret, access_token) } }
    let(:verb) { 'get' }
    let(:response) { Koala::HTTPService::Response.new(200, '', '') }

    describe "the appsecret_proof arguments" do
      describe "with an API access token present" do
        describe "and with an appsecret included on API initialization " do
          let(:api) { Koala::Facebook::API.new(access_token, appsecret) }

          it "will be included by default" do
            expect(Koala).to receive(:make_request).with(path, token_args.merge(appsecret_proof_args), verb, {}).and_return(response)
            api.api(path, {}, verb, :appsecret_proof => true)
          end
        end

        describe "but without an appsecret included on API initialization" do
          it "will not be included" do
            expect(Koala).to receive(:make_request).with(path, token_args, verb, {}).and_return(response)
            api.api(path, {}, verb, :appsecret_proof => true)
          end
        end
      end

      describe "but without an API access token present" do
        describe "and with an appsecret included on API initialization " do
          let(:api) { Koala::Facebook::API.new(nil, appsecret) }

          it "will not be included" do
            expect(Koala).to receive(:make_request).with(path, {}, verb, {}).and_return(response)
            api.api(path, {}, verb, :appsecret_proof => true)
          end
        end

        describe "but without an appsecret included on API initialization" do
          let(:api) { Koala::Facebook::API.new }

          it "will not be included" do
            expect(Koala).to receive(:make_request).with(path, {}, verb, {}).and_return(response)
            api.api(path, {}, verb, :appsecret_proof => true)
          end
        end
      end
    end
  end

  describe "#graph_call" do
    it "passes all arguments to the api method" do
      user = KoalaTest.user1
      args = {}
      verb = 'get'
      opts = {:a => :b}
      expect(@service).to receive(:api).with(user, args, verb, opts).and_return(dummy_response)
      @service.graph_call(user, args, verb, opts)
    end

    it "throws an APIError if the result hash has an error key" do
      allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(500, '{"error": "An error occurred!"}', {}))
      expect { @service.graph_call(KoalaTest.user1, {}) }.to raise_exception(Koala::Facebook::APIError)
    end

    it "passes the results through GraphCollection.evaluate" do
      allow(@service).to receive(:api).and_return(dummy_response)
      expect(Koala::Facebook::API::GraphCollection).to receive(:evaluate).with(dummy_response, @service)
      @service.graph_call("/me")
    end

    it "returns the results of GraphCollection.evaluate" do
      expected = {}
      allow(@service).to receive(:api).and_return(dummy_response)
      expect(Koala::Facebook::API::GraphCollection).to receive(:evaluate).and_return(expected)
      expect(@service.graph_call("/me")).to eq(expected)
    end

    it "returns the post_processing block's results if one is supplied" do
      other_result = [:a, 2, :three]
      block = Proc.new {|r| other_result}
      allow(@service).to receive(:api).and_return(dummy_response)
      expect(@service.graph_call("/me", {}, "get", {}, &block)).to eq(other_result)
    end

    it "gets the status of a Koala::HTTPService::Response if requested" do
      response = Koala::HTTPService::Response.new(200, '', {})
      allow(Koala).to receive(:make_request).and_return(response)

      expect(@service.graph_call('anything', {}, 'get', http_component: :status)).to eq(200)
    end

    it "gets the headers of a Koala::HTTPService::Response if requested" do
      headers = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, '', headers)
      allow(Koala).to receive(:make_request).and_return(response)

      expect(@service.graph_call('anything', {}, 'get', :http_component => :headers)).to eq(headers)
    end

    it "returns the entire response if http_component => :response" do
      http_component = :response
      response = Koala::HTTPService::Response.new(200, '', {})
      allow(Koala).to receive(:make_request).and_return(response)
      expect(@service.graph_call('anything', {}, 'get', :http_component => http_component)).to eq(response)
    end

    it "returns the body of the request as JSON if no http_component is given" do
      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, {})
      allow(Koala).to receive(:make_request).and_return(response)

      expect(@service.graph_call('anything')).to eq(result)
    end

    it "handles rogue true/false as responses" do
      expect(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
      expect(@service.graph_call('anything')).to be_truthy

      expect(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'false', {}))
      expect(@service.graph_call('anything')).to be_falsey
    end
  end

  describe "Rate limit hook" do
    it "is called when x-business-use-case-usage header is present" do
      api = Koala::Facebook::API.new('', '', ->(limits) {
        expect(limits["x-business-use-case-usage"]).to eq({"123456789012345"=>[{"type"=>"messenger", "call_count"=>1, "total_cputime"=>1, "total_time"=>1, "estimated_time_to_regain_access"=>0}]})
      })

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, { "x-business-use-case-usage" => "{\"123456789012345\":[{\"type\":\"messenger\",\"call_count\":1,\"total_cputime\":1,\"total_time\":1,\"estimated_time_to_regain_access\":0}]}" })
      allow(Koala).to receive(:make_request).and_return(response)

      api.graph_call('anything')
    end

    it "is called when x-ad-account-usage header is present" do
      api = Koala::Facebook::API.new('', '', ->(limits) {
        expect(limits["x-ad-account-usage"]).to eq({"acc_id_util_pct"=>9.67})
      })

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, { "x-ad-account-usage" => "{\"acc_id_util_pct\":9.67}" })
      allow(Koala).to receive(:make_request).and_return(response)

      api.graph_call('anything')
    end

    it "is called when x-app-usage header is present" do
      api = Koala::Facebook::API.new('', '', ->(limits) {
        expect(limits["x-app-usage"]).to eq({"call_count"=>0, "total_cputime"=>0, "total_time"=>0})
      })

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, { "x-app-usage" => "{\"call_count\":0,\"total_cputime\":0,\"total_time\":0}" })
      allow(Koala).to receive(:make_request).and_return(response)

      api.graph_call('anything')
    end

    it "isn't called if none of the rate limit header is present" do
      rate_limit_hook_called = false

      api = Koala::Facebook::API.new('', '', ->(limits) {
        rate_limit_hook_called = true
      })

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, {})
      allow(Koala).to receive(:make_request).and_return(response)

      api.graph_call('anything')

      expect(rate_limit_hook_called).to be(false)
    end

    it "isn't called if no rate limit hook is defined" do
      api = Koala::Facebook::API.new('', '', ->(limits) {
        #noop
      })

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, { "x-ad-account-usage" => "{\"acc_id_util_pct\"9.67}"})
      allow(Koala).to receive(:make_request).and_return(response)

      expect(Koala::Utils.logger).to receive(:error).with("JSON::ParserError: expected ':' after object key at line 1 column 19 while parsing x-ad-account-usage = {\"acc_id_util_pct\"9.67}")
      api.graph_call('anything')
    end

    it "logs an error if the rate limit header can't be properly parsed" do
      api = Koala::Facebook::API.new('', '', nil)

      result = {"a" => 2}
      response = Koala::HTTPService::Response.new(200, result.to_json, {})
      allow(Koala).to receive(:make_request).and_return(response)

      api.graph_call('anything')
    end
  end
end
