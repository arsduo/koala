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
    let(:post_processing) { lambda {} }

    # Most API methods have the same signature, we test get_object representatively
    # and the other methods which do some post-processing locally
    context '#get_object' do
      it 'is called' do
        post_processing.should_receive(:call).with("id" => 1, "name" => 1, "updated_time" => 1)
        @api.get_object('koppel', &post_processing)
      end

      it 'returns result of block' do
        post_processing.should_receive(:call).and_return('new result')
        @api.get_object('koppel', &post_processing).should == 'new result'
      end
    end

    context '#get_picture' do
      it 'is called with picture url' do
        post_processing.should_receive(:call).with('http://facebook.com/')
        @api.get_picture('lukeshepard', &post_processing)
      end

      it 'returns result of block' do
        post_processing.should_receive(:call).and_return('new result')
        @api.get_picture('lukeshepard', &post_processing).should == 'new result'
      end
    end

    context '#fql_multiquery' do
      before do
        MultiJson.stub(:dump)
        @api.should_receive(:get_object).and_return([{"name" => "query1", "fql_result_set" => [{"id" => 123}]},{"name" => "query2", "fql_result_set" => ["id" => 456]}])
      end

      it 'is called with resolved response' do
        resolved_result = { 'query1'=>[{'id'=>123}],'query2'=>[{'id'=>456}] }
        post_processing.should_receive(:call).with(resolved_result)
        @api.fql_multiquery(&post_processing)
      end

      it 'returns result of block' do
        post_processing.should_receive(:call).and_return('id'=>'123', 'id'=>'456')
        @api.fql_multiquery(&post_processing).should == {'id'=>'123', 'id'=>'456'}
      end
    end

    context '#get_page_access_token' do
      it 'is called with just access token' do
        post_processing.should_receive(:call).with(Koala::MockHTTPService::APP_ACCESS_TOKEN)
        @api.get_page_access_token '/my_page', &post_processing
      end

      it 'returns result of block' do
        post_processing.should_receive(:call).and_return('base64-encoded access token')
        @api.get_page_access_token('/my_page', &post_processing).should == 'base64-encoded access token'
      end
    end

  end

end
