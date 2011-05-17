require 'spec_helper'

describe "Koala::Facebook::GraphAPI in batch mode" do
  include LiveTestingDataHelper
  before :each do
    @api = Koala::Facebook::GraphAPI.new(@token)
    @fake_api = Koala::Facebook::GraphAPI.new("token2")
    @api_no_token = Koala::Facebook::GraphAPI.new
  end 
  
  # making requests
  describe "making requests" do
    context "with a token" do
      it 'should be able to get data about a user and me at the same time' do
        me, koppel = Koala::Facebook::GraphAPI.batch do
          @api.get_object('me')
          @api.get_object('koppel')
        end
        me['id'].should_not be_nil
        koppel['id'].should_not be_nil
      end

      it 'should be able to make a get_picture call inside of a batch' do
        pictures = Koala::Facebook::GraphAPI.batch do
          @api.get_picture('me')
        end
        pictures.first.should_not be_empty
      end

      it 'should be able to make mixed calls inside of a batch' do
        me, friends = Koala::Facebook::GraphAPI.batch do
          @api.get_object('me')
          @api.get_connections('me', 'friends')
        end
        me['id'].should_not be_nil
        friends.should be_a(Array)
      end
    end
    
    context "mixed token and non-token" do
      it 'should be able to get data about a user and me at the same time' do
        me, koppel = Koala::Facebook::GraphAPI.batch do
          @api.get_object('me')
          @api_no_token.get_object('koppel')
        end
        me['id'].should_not be_nil
        koppel['id'].should_not be_nil
      end

      it 'should be able to make a get_picture call inside of a batch' do
        pictures = Koala::Facebook::GraphAPI.batch do
          @api.get_picture('me')
          @api_no_token.get_picture('koppel')
        end
        pictures.first.should_not be_empty
      end
    end
    
    describe "handling errors" do
      it 'returns an APIError object among the results if you try to request a private object w/o a token' do
        result = Koala::Facebook::GraphAPI.batch do
          @api.get_object('me')
          @api_no_token.get_connections('lukeshepard', "likes")
        end

        result[1].should be_a(Koala::Facebook::APIError)
      end
      
      it 'returns other results successfully even if an error occurs in one' do
        result = Koala::Facebook::GraphAPI.batch do
          @api.get_object('me')
          @api_no_token.get_connections('lukeshepard', "likes")
        end

        result[0].should be_a(Hash)
      end      
    end
  end

  it "makes get and post requests"
  it "makes batch requests for APIs with a token"
  it "makes batch requests for APIs without a token"
  it "makes batch requests for multiple APIs with and without tokens"
  it "uses ssl if any request includes an access token"
  it "uploads binary files appropriately"
  
  # batch interface
  it "sets the batch_mode flag inside batch mode"
  it "throws an error if you access the batch_calls queue outside a batch block"
  it "clears the batch queue between requests"
end