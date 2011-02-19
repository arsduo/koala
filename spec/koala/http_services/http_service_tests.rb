require 'koala/http_services'
class HTTPServiceTests < Test::Unit::TestCase
  class Bear
    include Koala::HTTPService
  end

  describe "common methods" do
    describe "always_use_ssl accessor" do
      it "should be added" do
        Bear.methods.should include("always_use_ssl")
        Bear.methods.should include("always_use_ssl=")        
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

  end

end