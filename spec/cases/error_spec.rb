require 'spec_helper'

describe Koala::Facebook::APIError do
  it "is a StandardError" do
    Koala::Facebook::APIError.new.should be_a(StandardError)
  end

  it "has an accessor for fb_error_type" do
    Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:fb_error_type)
    Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:fb_error_type=)
  end

  it "has an accessor for raw_response" do
    Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:raw_response)
    Koala::Facebook::APIError.instance_methods.map(&:to_sym).should include(:raw_response=)
  end

  it "sets raw_response to the provided error details" do
    error_response = {"type" => "foo", "other_details" => "bar"}
    Koala::Facebook::APIError.new(error_response).raw_response.should == error_response
  end
  
  it "sets fb_error_type to details['type']" do
    type = "foo"
    Koala::Facebook::APIError.new("type" => type).fb_error_type.should == type
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

