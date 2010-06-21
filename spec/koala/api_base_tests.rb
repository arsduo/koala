class ApiBaseTests < Test::Unit::TestCase
  describe "Koala API base class" do
    before(:each) do
      @service = Koala::Facebook::API.new  
    end
    
    it "should not include an access token if none was given" do
      Koala.should_receive(:make_request).with(
        anything,
        hash_not_including('access_token' => 1),
        anything,
        anything
      ).and_return(Koala::Response.new(200, "", ""))
      
      @service.api('anything')
    end
    
    it "should include an access token if given" do
      token = 'adfadf'
      service = Koala::Facebook::API.new token
      
      Koala.should_receive(:make_request).with(
        anything,
        hash_including('access_token' => token),
        anything,
        anything
      ).and_return(Koala::Response.new(200, "", ""))
      
      service.api('anything')
    end
    
    it "should get the attribute of a Koala::Response given by the http_component parameter" do
      http_component = :method_name
      
      response = mock('Mock KoalaResponse')
      response.should_receive(http_component).and_return('')
      response.stub(:body).and_return('')
      
      Koala.stub(:make_request).and_return(response)
      
      @service.api('anything', 'get', {}, :http_component => http_component)
    end
    
    it "should return the body of the request as JSON if no http_component is given" do
      response = stub('response', :body => 'body')
      Koala.stub(:make_request).and_return(response)
      
      json_body = mock('JSON body')
      JSON.stub(:parse).and_return([json_body])
      
      @service.api('anything').should == json_body
    end
    
    it "should execute a block with the response body if passed one" do
      body = '{}'
      Koala.stub(:make_request).and_return(Koala::Response.new(200, body, {}))
      
      yield_test = mock('Yield Tester')
      yield_test.should_receive(:pass)
      
      @service.api('anything') do |arg| 
        yield_test.pass
        arg.should == JSON.parse(body)
      end
    end
    
    it "should handle rogue true/false as responses" do
      Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'true', {}))
      @service.api('anything').should be_true
      
      Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'false', {}))
      @service.api('anything').should be_false
    end
  end
end

shared_examples_for "methods that return overloaded strings" do
  before :each do
    @key ||= "access_token"
  end
  
  it "should be overloaded to be backward compatible" do
    @result.respond_to?(:[]).should be_true
  end

  it "should allow hash access to the access token info" do
    @result[@key].should == @result
  end

  it "should output a deprecation warning when the result is used as a hash" do 
    out = nil
  
    begin
      # we want to capture the deprecation warning as well as the output
      # credit to http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/ for the technique
      out = StringIO.new
      $stdout = out
      @result[@key]
    ensure
      $stdout = STDOUT
    end
  
    # ensure we got a warning
    out.should_not be_nil
  end
end