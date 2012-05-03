require 'spec_helper'

describe "Koala::Facebook::API" do
  before(:each) do
    @service = Koala::Facebook::API.new
  end

  it "doesn't include an access token if none was given" do
    Koala.should_receive(:make_request).with(
      anything,
      hash_not_including('access_token' => 1),
      anything,
      anything
    ).and_return(Koala::HTTPService::Response.new(200, "", ""))

    @service.api('anything')
  end

  it "includes an access token if given" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token

    Koala.should_receive(:make_request).with(
      anything,
      hash_including('access_token' => token),
      anything,
      anything
    ).and_return(Koala::HTTPService::Response.new(200, "", ""))

    service.api('anything')
  end

  it "has an attr_reader for access token" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token
    service.access_token.should == token
  end

  it "gets the attribute of a Koala::HTTPService::Response given by the http_component parameter" do
    http_component = :method_name

    response = mock('Mock KoalaResponse', :body => '', :status => 200)
    result = stub("result")
    response.stub(http_component).and_return(result)
    Koala.stub(:make_request).and_return(response)

    @service.api('anything', {}, 'get', :http_component => http_component).should == result
  end

  it "returns the entire response if http_component => :response" do
    http_component = :response
    response = mock('Mock KoalaResponse', :body => '', :status => 200)
    Koala.stub(:make_request).and_return(response)    
    @service.api('anything', {}, 'get', :http_component => http_component).should == response
  end

  it "returns the body of the request as JSON if no http_component is given" do
    response = stub('response', :body => 'body', :status => 200)
    Koala.stub(:make_request).and_return(response)

    json_body = mock('JSON body')
    MultiJson.stub(:load).and_return([json_body])

    @service.api('anything').should == json_body
  end

  it "executes an error checking block if provided" do
    response = Koala::HTTPService::Response.new(200, '{}', {})
    Koala.stub(:make_request).and_return(response)

    yield_test = mock('Yield Tester')
    yield_test.should_receive(:pass)

    @service.api('anything', {}, "get") do |arg|
      yield_test.pass
      arg.should == response
    end
  end

  it "raises an API error if the HTTP response code is greater than or equal to 500" do
    Koala.stub(:make_request).and_return(Koala::HTTPService::Response.new(500, 'response body', {}))

    lambda { @service.api('anything') }.should raise_exception(Koala::Facebook::APIError)
  end

  it "handles rogue true/false as responses" do
    Koala.should_receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
    @service.api('anything').should be_true

    Koala.should_receive(:make_request).and_return(Koala::HTTPService::Response.new(200, 'false', {}))
    @service.api('anything').should be_false
  end

  describe "with regard to leading slashes" do
    it "adds a leading / to the path if not present" do
      path = "anything"
      Koala.should_receive(:make_request).with("/#{path}", anything, anything, anything).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
      @service.api(path)
    end

    it "doesn't change the path if a leading / is present" do
      path = "/anything"
      Koala.should_receive(:make_request).with(path, anything, anything, anything).and_return(Koala::HTTPService::Response.new(200, 'true', {}))
      @service.api(path)
    end
  end

  describe "with an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  describe "without an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end
