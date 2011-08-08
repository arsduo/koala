require 'spec_helper'

describe "Koala" do
  it "has an http_service accessor" do
    Koala.should respond_to(:http_service)
    Koala.should respond_to(:http_service=)
  end

  it "has an http_options accessor" do
    Koala.should respond_to(:http_options)
    Koala.should respond_to(:http_options=)
  end

  define "make_request" do
    it "passes all its arguments to the http_service" do
      http_service = stub("http_service")
      path = "foo"
      args = {:a => 2}
      verb = "get"
      options = {:c => :d}
      http_service.should_receive(:make_request).with(path, args, verb, options)
      Koala.make_request(path, args, verb, options)
    end
  end

end