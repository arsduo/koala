require 'spec_helper'

describe Koala::Facebook::APIError do
  it "is a Koala::KoalaError" do
    Koala::Facebook::APIError.new(nil, nil).should be_a(Koala::KoalaError)
  end

  [:fb_error_type, :fb_error_code, :fb_error_subcode, :fb_error_message, :http_status, :response_body].each do |accessor|
    it "has an accessor for #{accessor}" do
      Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(accessor)
      Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:"#{accessor}=")
    end
  end

  it "sets http_status to the provided status" do
    error_response = '{ "error": {"type": "foo", "other_details": "bar"} }'
    Koala::Facebook::APIError.new(400, error_response).response_body.should == error_response
  end

  it "sets response_body to the provided response body" do
    Koala::Facebook::APIError.new(400, '').http_status.should == 400
  end

  context "with an error_info hash" do
    let(:error) { 
      error_info = {
        'type' => 'type',
        'message' => 'message',
        'code' => 1,
        'error_subcode' => 'subcode'
      }
      Koala::Facebook::APIError.new(400, '', error_info)
    }

    {
      :fb_error_type => 'type',
      :fb_error_message => 'message',
      :fb_error_code => 1,
      :fb_error_subcode => 'subcode'
    }.each_pair do |accessor, value|
      it "sets #{accessor} to #{value}" do
        error.send(accessor).should == value
      end
    end

    it "sets the error message \"type: error_info['type'], code: error_info['code'], error_subcode: error_info['error_subcode'], message: error_info['message'] [HTTP http_status]\"" do
      error.message.should == "type: type, code: 1, error_subcode: subcode, message: message [HTTP 400]"
    end
  end

  context "with an error_info string" do
    it "sets the error message \"error_info [HTTP http_status]\"" do
      error_info = "Facebook is down."
      error = Koala::Facebook::APIError.new(400, '', error_info)
      error.message.should == "Facebook is down. [HTTP 400]"
    end
  end

  context "with no error_info and a response_body containing error JSON" do
    it "should extract the error info from the response body" do
      response_body = '{ "error": { "type": "type", "message": "message", "code": 1, "error_subcode": "subcode" } }'
      error = Koala::Facebook::APIError.new(400, response_body)
      {
        :fb_error_type => 'type',
        :fb_error_message => 'message',
        :fb_error_code => 1,
        :fb_error_subcode => 'subcode'
      }.each_pair do |accessor, value|
        error.send(accessor).should == value
      end
    end
  end

end

describe Koala::KoalaError do
  it "is a StandardError" do
     Koala::KoalaError.new.should be_a(StandardError)
  end
end

describe Koala::Facebook::OAuthSignatureError do
  it "is a Koala::KoalaError" do
     Koala::KoalaError.new.should be_a(Koala::KoalaError)
  end
end

describe Koala::Facebook::BadFacebookResponse do
  it "is a Koala::Facebook::APIError" do
     Koala::Facebook::BadFacebookResponse.new(nil, nil).should be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::OAuthTokenRequestError do
  it "is a Koala::Facebook::APIError" do
     Koala::Facebook::OAuthTokenRequestError.new(nil, nil).should be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::ServerError do
  it "is a Koala::Facebook::APIError" do
     Koala::Facebook::ServerError.new(nil, nil).should be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::ClientError do
  it "is a Koala::Facebook::APIError" do
     Koala::Facebook::ClientError.new(nil, nil).should be_a(Koala::Facebook::APIError)
  end
end

describe Koala::Facebook::AuthenticationError do
  it "is a Koala::Facebook::ClientError" do
     Koala::Facebook::AuthenticationError.new(nil, nil).should be_a(Koala::Facebook::ClientError)
  end
end
