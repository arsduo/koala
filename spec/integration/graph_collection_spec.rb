require 'spec_helper'

module Koala
  RSpec.describe "requests using GraphCollections" do
    let(:api) { Facebook::API.new(KoalaTest.vcr_oauth_token) }

    before :each do
      # use the right version of the API as of the writing of this test
      Koala.config.api_version = "v2.2"
    end

    it "can access the next page of a friend list" do
      KoalaTest.with_vcr_unless_live("friend_list_next_page") do
        result = api.get_connection("me", "friends")
        expect(result).not_to be_empty
        expect(result.next_page).not_to be_empty
      end
    end
  end
end

