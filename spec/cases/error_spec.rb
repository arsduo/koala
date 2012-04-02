require 'spec_helper'

describe Koala::Facebook::APIError do
  it "is a StandardError" do
    Koala::Facebook::APIError.new.should be_a(StandardError)
  end

  [:fb_error_type, :fb_error_code, :fb_error_message, :raw_response].each do |accessor|
    it "has an accessor for #{accessor}" do
      Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(accessor)
      Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:"#{accessor}=")
    end
  end

  it "sets raw_response to the provided error details" do
    error_response = {"type" => "foo", "other_details" => "bar"}
    Koala::Facebook::APIError.new(error_response).raw_response.should == error_response
  end

  {
    :fb_error_type => 'type',
    :fb_error_message => 'message',
    :fb_error_code => 'code'
  }.each_pair do |accessor, key|
    it "sets #{accessor} to details['#{key}']" do
      value = "foo"
      Koala::Facebook::APIError.new(key => value).send(accessor).should == value
    end
  end

  it "sets the error message details['type']: details['message']" do
    type = "foo"
    message = "bar"
    error = Koala::Facebook::APIError.new("type" => type, "message" => message)
    error.message.should =~ /#{type}/
    error.message.should =~ /#{message}/
  end
end

describe Koala::KoalaError do
  it "is a StandardError" do
     Koala::KoalaError.new.should be_a(StandardError)
  end
end

