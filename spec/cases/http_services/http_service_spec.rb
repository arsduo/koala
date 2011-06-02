require 'spec_helper'


class Bear
  include Koala::HTTPService
end

describe "Koala::HTTPService" do

  describe "common methods" do
    describe "always_use_ssl accessor" do
      it "should be added" do
        # in Ruby 1.8, .methods returns strings
        # in Ruby 1.9, .method returns symbols 
        Bear.methods.collect {|m| m.to_sym}.should include(:always_use_ssl)
        Bear.methods.collect {|m| m.to_sym}.should include(:always_use_ssl=)
      end
    end
    
    describe "proxy accessor" do
      it "should be added" do
        # in Ruby 1.8, .methods returns strings
        # in Ruby 1.9, .method returns symbols 
        Bear.methods.collect {|m| m.to_sym}.should include(:proxy)
        Bear.methods.collect {|m| m.to_sym}.should include(:proxy=)
      end
    end
    
    describe "timeout accessor" do
      it "should be added" do
        # in Ruby 1.8, .methods returns strings
        # in Ruby 1.9, .method returns symbols 
        Bear.methods.collect {|m| m.to_sym}.should include(:timeout)
        Bear.methods.collect {|m| m.to_sym}.should include(:timeout=)
      end
    end
    
    describe "server" do
      describe "without options[:beta]" do
        it "should return the rest server if options[:rest_api]" do
          Bear.server(:rest_api => true).should == Koala::Facebook::REST_SERVER
        end

        it "should return the rest server if !options[:rest_api]" do
          Bear.server(:rest_api => false).should == Koala::Facebook::GRAPH_SERVER
          Bear.server({}).should == Koala::Facebook::GRAPH_SERVER
        end
      end
      
      describe "without options[:beta]" do
        before :each do
          @options = {:beta => true}
        end
        
        it "should return the rest server if options[:rest_api]" do
          server = Bear.server(@options.merge(:rest_api => true))
          server.should =~ Regexp.new(Koala::Facebook::REST_SERVER)
          server.should =~ /beta\./
        end

        it "should return the rest server if !options[:rest_api]" do
          server = Bear.server(:beta => true)
          server.should =~ Regexp.new(Koala::Facebook::GRAPH_SERVER)
          server.should =~ /beta\./
        end
      end
    end

    describe "#encode_params" do
      it "should return an empty string if param_hash evaluates to false" do
        Bear.encode_params(nil).should == ''
      end

      it "should convert values to JSON if the value is not a String" do
        val = 'json_value'
        not_a_string = 'not_a_string'
        not_a_string.stub(:is_a?).and_return(false)
        not_a_string.should_receive(:to_json).and_return(val)

        string = "hi"

        args = {
          not_a_string => not_a_string,
          string => string
        }

        result = Bear.encode_params(args)
        result.split('&').find do |key_and_val|
          key_and_val.match("#{not_a_string}=#{val}")
        end.should be_true
      end

      it "should escape all values" do
        args = Hash[*(1..4).map {|i| [i.to_s, "Value #{i}($"]}.flatten]

        result = Bear.encode_params(args)
        result.split('&').each do |key_val|
          key, val = key_val.split('=')
          val.should == CGI.escape(args[key])
        end
      end

      it "should convert all keys to Strings" do
        args = Hash[*(1..4).map {|i| [i, "val#{i}"]}.flatten]

        result = Bear.encode_params(args)
        result.split('&').each do |key_val|
          key, val = key_val.split('=')
          key.should == args.find{|key_val_arr| key_val_arr.last == val}.first.to_s
        end
      end
    end
  end

end