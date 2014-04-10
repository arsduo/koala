require 'spec_helper'

describe 'Koala::Facebook::GraphAPIMethods' do
  before do
    @api = Koala::Facebook::API.new(@token)
    # app API
    @app_id = KoalaTest.app_id
    @app_access_token = KoalaTest.app_access_token
    @app_api = Koala::Facebook::API.new(@app_access_token)
  end

  describe 'post-processing for' do
    let(:result) { double("result") }
    let(:post_processing) { lambda {|arg| {"result" => result, "args" => arg} } }

    # Most API methods have the same signature, we test get_object representatively
    # and the other methods which do some post-processing locally
    context '#get_object' do
      it 'returns result of block' do
        allow(@api).to receive(:api).and_return(double("other results"))
        expect(@api.get_object('koppel', &post_processing)["result"]).to eq(result)
      end

      it "doesn't add token to received arguments" do
        args = {}.freeze
        expect(Koala).to receive(:make_request).and_return(Koala::HTTPService::Response.new(200, "", ""))
        expect(@api.get_object('koppel', args, &post_processing)["result"]).to eq(result)
      end
    end

    context '#get_picture' do
      it 'returns result of block' do
        allow(@api).to receive(:api).and_return("Location" => double("other result"))
        expect(@api.get_picture('lukeshepard', &post_processing)["result"]).to eq(result)
      end
    end

    context '#fql_multiquery' do
      before do
        expect(@api).to receive(:get_object).and_return([
          {"name" => "query1", "fql_result_set" => [{"id" => 123}]},
          {"name" => "query2", "fql_result_set" => ["id" => 456]}
        ])
      end

      it 'is called with resolved response' do
        resolved_result = {
          'query1' => [{'id' => 123}],
          'query2' => [{'id' => 456}]
        }
        response = @api.fql_multiquery({}, &post_processing)
        expect(response["args"]).to eq(resolved_result)
        expect(response["result"]).to eq(result)
      end
    end

    context '#get_page_access_token' do
      it 'returns result of block' do
        token = Koala::MockHTTPService::APP_ACCESS_TOKEN
        allow(@api).to receive(:api).and_return("access_token" => token)
        response = @api.get_page_access_token('facebook', &post_processing)
        expect(response["args"]).to eq(token)
        expect(response["result"]).to eq(result)
      end
    end
  end

  context '#graph_call' do
    describe "the appsecret_proof option" do
      let(:path) { '/path' }

      it "is enabled by default if an app secret is present" do
        api = Koala::Facebook::API.new(@token, "mysecret")
        expect(api).to receive(:api).with(path, {}, 'get', :appsecret_proof => true)
        api.graph_call(path)
      end

      it "can be disabled manually" do
        api = Koala::Facebook::API.new(@token, "mysecret")
        expect(api).to receive(:api).with(path, {}, 'get', hash_not_including(appsecret_proof: true))
        api.graph_call(path, {}, "get", appsecret_proof: false)
      end

      it "isn't included if no app secret is present" do
        expect(@api).to receive(:api).with(path, {}, 'get', {})
        @api.graph_call(path)
      end
    end
  end
end
