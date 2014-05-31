require 'spec_helper'

describe "Koala::Facebook::API" do
  before(:each) do
    @service = Koala::Facebook::API.new
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

  it "has an attr_reader for access token" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token
    expect(service.access_token).to eq(token)
  end

  it "has an attr_reader for app_secret" do
    secret = double
    service = Koala::Facebook::API.new(@token, secret)
    expect(service.app_secret).to eq(secret)
  end

  it "gets the attribute of a Koala::HTTPService::Response given by the http_component parameter" do
    http_component = :method_name

    response = double('Mock KoalaResponse', :body => '', :status => 200)
    result = double("result")
    allow(response).to receive(http_component).and_return(result)
    allow(Koala).to receive(:make_request).and_return(response)

    expect(@service.api('anything', {}, 'get', :http_component => http_component)).to eq(result)
  end

  it "returns the entire response if http_component => :response" do
    http_component = :response
    response = double('Mock KoalaResponse', :body => '', :status => 200)
    allow(Koala).to receive(:make_request).and_return(response)
    expect(@service.api('anything', {}, 'get', :http_component => http_component)).to eq(response)
  end

  it "turns arrays of non-enumerables into comma-separated arguments" do
    args = [12345, {:foo => [1, 2, "3", :four]}]
    expected = ["/12345", {:foo => "1,2,3,four"}, "get", {}]
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

  it "returns the body of the request as JSON if no http_component is given" do
    response = double('response', :body => 'body', :status => 200)
    allow(Koala).to receive(:make_request).and_return(response)

    json_body = double('JSON body')
    allow(MultiJson).to receive(:load).and_return([json_body])

    expect(@service.api('anything')).to eq(json_body)
  end

  it "executes an error checking block if provided" do
    response = Koala::HTTPService::Response.new(200, '{}', {})
    allow(Koala).to receive(:make_request).and_return(response)

    yield_test = double('Yield Tester')
    expect(yield_test).to receive(:pass)

    @service.api('anything', {}, "get") do |arg|
      yield_test.pass
      expect(arg).to eq(response)
    end
  end

  it "raises an API error if the HTTP response code is greater than or equal to 500" do
    allow(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(500, 'response body', {}))

    expect { @service.api('anything') }.to raise_exception(Koala::Facebook::APIError)
  end

  it "handles rogue true/false as responses" do
    expect(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
    expect(@service.api('anything')).to be_truthy

    expect(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'false', {}))
    expect(@service.api('anything')).to be_falsey
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
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  describe "without an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
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
end
