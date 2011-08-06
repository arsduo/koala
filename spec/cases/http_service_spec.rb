require 'spec_helper'


describe "Koala::HTTPService" do

  describe "faraday_configuration accessor" do
    it "should be added" do
      # in Ruby 1.8, .methods returns strings
      # in Ruby 1.9, .method returns symbols 
      Koala::HTTPService.methods.collect {|m| m.to_sym}.should include(:faraday_configuration)
      Koala::HTTPService.methods.collect {|m| m.to_sym}.should include(:faraday_configuration=)
    end
  end
  
  describe "DEFAULT_MIDDLEWARE" do
    before :each do 
      @builder = stub("Faraday connection builder")
      @builder.stub(:request)
      @builder.stub(:adapter)
    end
    
    it "is defined" do
      Koala::HTTPService.const_defined?("DEFAULT_MIDDLEWARE").should be_true
    end
    
    it "adds multipart" do
      @builder.should_receive(:request).with(:multipart)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end
    
    it "adds url_encoded" do
      @builder.should_receive(:request).with(:url_encoded)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end
    
    it "uses the default adapter" do
      adapter = :testing_now
      Faraday.stub(:default_adapter).and_return(adapter)
      @builder.should_receive(:adapter).with(adapter)
      Koala::HTTPService::DEFAULT_MIDDLEWARE.call(@builder)
    end
  end
  
  describe "server" do
    describe "with no options" do
      it "returns the REST server if options[:rest_api]" do
        Koala::HTTPService.server(:rest_api => true).should =~ Regexp.new(Koala::Facebook::REST_SERVER)
      end

      it "returns the graph server if !options[:rest_api]" do
        Koala::HTTPService.server(:rest_api => false).should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER)
        Koala::HTTPService.server({}).should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER)
      end
    end

    describe "with options[:beta]" do
      before :each do
        @options = {:beta => true}
      end
      
      it "returns the beta REST server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        server.should =~ Regexp.new("beta.#{Koala::Facebook::REST_SERVER}")
      end

      it "returns the beta rest server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new("beta.#{Koala::Facebook::GRAPH_SERVER}")
      end
    end
    
    describe "with options[:video]" do
      before :each do
        @options = {:video => true}
      end
      
      it "should return the REST video server if options[:rest_api]" do
        server = Koala::HTTPService.server(@options.merge(:rest_api => true))
        server.should =~ Regexp.new(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end

      it "should return the graph video server if !options[:rest_api]" do
        server = Koala::HTTPService.server(@options)
        server.should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER.gsub(/\.facebook/, "-video.facebook"))
      end
    end
  end

  describe "#encode_params" do
    it "should return an empty string if param_hash evaluates to false" do
      Koala::HTTPService.encode_params(nil).should == ''
    end

    it "should convert values to JSON if the value is not a String" do
      val = 'json_value'
      not_a_string = 'not_a_string'
      not_a_string.stub(:is_a?).and_return(false)
      MultiJson.should_receive(:encode).with(not_a_string).and_return(val)

      string = "hi"

      args = {
        not_a_string => not_a_string,
        string => string
      }

      result = Koala::HTTPService.encode_params(args)
      result.split('&').find do |key_and_val|
        key_and_val.match("#{not_a_string}=#{val}")
      end.should be_true
    end

    it "should escape all values" do
      args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        val.should == CGI.escape(args[key])
      end
    end

    it "should convert all keys to Strings" do
      args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

      result = Koala::HTTPService.encode_params(args)
      result.split('&').each do |key_val|
        key, val = key_val.split('=')
        key.should == args.find{|key_val_arr| key_val_arr.last == val}.first.to_s
      end
    end
  end
end
