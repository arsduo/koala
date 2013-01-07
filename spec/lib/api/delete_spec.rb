require "spec_helper"

module Koala
  module Facebook
    describe API do
      before :each do
        @api = Koala::Facebook::API.new(@token)
        @api_without_token = Koala::Facebook::API.new
        # app API
        @app_id = KoalaTest.app_id
        @app_access_token = KoalaTest.app_access_token
        @app_api = Koala::Facebook::API.new(@app_access_token)
      end

      describe "deleting data from the graph" do
        describe "#delete_object" do
          context "without an access token" do
            it "can't delete posts" do
              # test post on the Ruby SDK Test application
              lambda { @result = @api.delete_object("115349521819193_113815981982767") }.should raise_error(Koala::Facebook::AuthenticationError)
            end
          end

          context "with an access token" do
            it "can delete posts" do
              result = @api.put_wall_post("Hello, world, from the test suite delete method!")
              object_id_to_delete = result["id"]
              delete_result = @api.delete_object(object_id_to_delete)
              delete_result.should == true
            end
          end
        end

        describe "#delete_like" do
          context "without an access token" do
            it "can't delete a like" do
              lambda { @api.delete_like("7204941866_119776748033392") }.should raise_error(Koala::Facebook::AuthenticationError)
            end
          end

          context "with an access token" do
            it "can delete likes" do
              result = @api.put_wall_post("Hello, world, from the test suite delete like method!")
              @temporary_object_id = result["id"]
              @api.put_like(@temporary_object_id)
              delete_like_result = @api.delete_like(@temporary_object_id)
              delete_like_result.should == true
            end
          end
        end
      end
    end
  end
end
