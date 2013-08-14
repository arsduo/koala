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
    let(:result) { stub("result") }
    let(:post_processing) { lambda {|arg| {"result" => result, "args" => arg} } }

    # Most API methods have the same signature, we test get_object representatively
    # and the other methods which do some post-processing locally
    context '#get_object' do
      it 'returns result of block' do
        @api.stub(:api).and_return(stub("other results"))
        @api.get_object('koppel', &post_processing)["result"].should == result
      end
    end

    context '#get_picture' do
      it 'returns result of block' do
        @api.stub(:api).and_return("Location" => stub("other result"))
        @api.get_picture('lukeshepard', &post_processing)["result"].should == result
      end
    end

    context '#fql_multiquery' do
      before do
        @api.should_receive(:get_object).and_return([
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
        response["args"].should == resolved_result
        response["result"].should == result
      end
    end

    context '#get_page_access_token' do
      it 'returns result of block' do
        token = Koala::MockHTTPService::APP_ACCESS_TOKEN
        @api.stub(:api).and_return("access_token" => token)
        response = @api.get_page_access_token('facebook', &post_processing)
        response["args"].should == token
        response["result"].should == result
      end
    end
  end

  context '#graph_call' do
    describe "the appsecret_proof option" do
      let(:path) { '/path' }

      it "should be passed to #api" do
        @api.should_receive(:api).with(path, {}, 'get', :appsecret_proof => true)

        @api.graph_call(path)
      end
    end
  end
end
