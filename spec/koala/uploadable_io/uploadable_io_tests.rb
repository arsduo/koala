# fake MIME::Types
module Koala::MIME
  module Types
    def self.type_for(type)
      # this should be faked out in tests
      nil
    end
  end
end

class UploadableIOTests < Test::Unit::TestCase
  include Koala

  describe UploadableIO do
    describe "the constructor" do
      it "should raise a KoalaError if the parameters are incorrect" do
        bad_params = [1, 4]
        
        lambda { UploadableIO.new(*bad_params) }.should raise_exception(KoalaError)
      end
      
      it "should accept an open IO and content type" do
        params = [
          File.open(File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")),
          "image/jpg"
        ]
        
        lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
      end
      
      it "should accept a file path and content type" do
        params = [
          File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg"),
          "image/jpg"
        ]
        
        lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
      end
      
      it "should accept a single Hash argument" do
        lambda { UploadableIO.new({}) }.should_not raise_exception(Exception)
        lambda { UploadableIO.new({}) }.should_not raise_exception(KoalaError)
      end 
      
      describe "for files with with recognizable MIME types" do
        # what that means is tested below
        
        it "should accept a file object alone" do
          params = [
            File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")
          ]
          lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
        end
        
        it "should accept a file path alone" do
          params = [
            File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")
          ]
          lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
        end
      end
    end
    
    describe "getting an UploadIO" do
      before(:each) do
        @upload_io = stub("UploadIO")
        UploadIO.stub!(:new).with(anything, anything, anything).and_return(@upload_io)
      end
      
      it "should always have a dummy file name" do
        UploadableIO.new("/dummy/path", "dummy/content-type").to_upload_io.should == @upload_io
      end
      
      describe "when given an open IO and content type" do
        before(:each) do
          @koala_io_params = [
            File.open(File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")),
            "image/jpg"
          ]
        end
        
        it "should return an UploadIO with the same io" do
          @koala_io_params[0] = File.open(File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg"))
          
          UploadIO.should_receive(:new).with(@koala_io_params[0], anything, anything).and_return(@upload_io)
          
          UploadableIO.new(*@koala_io_params).to_upload_io.should == @upload_io
        end
        
        it "should return an UplaodIO with the same content_type" do
          @koala_io_params[1] = stub('Content Type')
          
          UploadIO.should_receive(:new).with(anything, @koala_io_params[1], anything).and_return(@upload_io)
          
          UploadableIO.new(*@koala_io_params).to_upload_io.should == @upload_io
        end
      end
      
      describe "when given a file path and content type" do
        before(:each) do
          @koala_io_params = [
            File.open(File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")),
            "image/jpg"
          ]
        end
        
        it "should return an UploadIO with the same file path" do
          @koala_io_params[0] = "/stub/path/to/file"
          
          UploadIO.should_receive(:new).with(@koala_io_params[0], anything, anything).and_return(@upload_io)
          
          UploadableIO.new(*@koala_io_params).to_upload_io.should == @upload_io          
        end
        
        it "should return an UploadIO with the same content type" do
          @koala_io_params[1] = stub('Content Type')
          
          UploadIO.should_receive(:new).with(anything, @koala_io_params[1], anything).and_return(@upload_io)
          
          UploadableIO.new(*@koala_io_params).to_upload_io.should == @upload_io          
        end
      end
      
      describe "when not given a content type" do
        shared_examples_for "UploadableIO determining a content type" do
          describe "if MIME::Types is available" do
            it "should return an UploadIO with MIME::Types-determined type if the type exists" do
              type_result = ["type"]
              Koala::MIME::Types.stub(:type_for).and_return(type_result)
              UploadableIO.new("myfilename.txt").content_type.should == type_result.first          
            end
          end
          
          shared_examples_for "MIME::Types can't return results" do
            {
              "jpg" => "image/jpeg",
              "jpeg" => "image/jpeg",
              "png" => "image/png", 
              "gif" => "image/gif"
            }.each_pair do |extension, mime_type|
              it "should properly get content types for #{extension} using basic analysis" do
                UploadableIO.new("filename.#{extension}").content_type.should == mime_type
              end
            end
            
            it "should throw an exception if the MIME type can't be determined" do
              lambda { UploadableIO.new("badfile.badextension") }.should raise_exception(KoalaError)  
            end
          end  
          
          describe "if MIME::Types is unavailable" do
            before :each do
              # fake that MIME::Types doesn't exist
              Koala::MIME::Types.stub(:type_for).and_raise(NameError)
            end
            it_should_behave_like "MIME::Types can't return results"
          end 

          describe "if MIME::Types can't find the result" do
            before :each do
              # fake that MIME::Types doesn't exist
              Koala::MIME::Types.stub(:type_for).and_return([])
            end
            
            it_should_behave_like "MIME::Types can't return results"
          end
        end # shared example group
  
        describe "for paths" do
          before :each do
            @koala_io_params = [
              "filename.abcd"
            ]
          end
          
          it_should_behave_like "UploadableIO determining a content type"
          
        end
  
      end
      
      describe "when given a Rails 3 ActionDispatch::Http::UploadedFile" do
        before(:each) do
          @tempfile = stub('Tempfile', :path => true)
          @uploaded_file = stub('ActionDispatch::Http::UploadedFile', 
            :content_type => true,
            :tempfile => @tempfile
          )

          @uploaded_file.stub!(:respond_to?).with(:content_type).and_return(true)
          @uploaded_file.stub!(:respond_to?).with(:tempfile).and_return(@tempfile)
          @tempfile.stub!(:respond_to?).with(:path).and_return(true)          
        end
        
        it "should get the content type via the content_type method" do
          upload_io = stub('UploadIO')
          expected_content_type = stub('Content Type')
          @uploaded_file.should_receive(:content_type).and_return(expected_content_type)

          UploadIO.should_receive(:new).with(anything, expected_content_type, anything).and_return(upload_io)
          
          UploadableIO.new(@uploaded_file).to_upload_io.should == upload_io
        end
        
        it "should get the path from the tempfile associated with the UploadedFile" do
          upload_io = stub('UploadIO')
          expected_path = stub('Tempfile')
          @tempfile.should_receive(:path).and_return(expected_path)

          UploadIO.should_receive(:new).with(expected_path, anything, anything).and_return(upload_io)
          
          UploadableIO.new(@uploaded_file).to_upload_io.should == upload_io          
        end
      end
      
      describe "when given a Sinatra file parameter hash" do
        before(:each) do
          @file_hash = {
            :type => "type",
            :tempfile => "Tempfile"
          }
        end
        
        it "should get the content type from the :type key" do
          upload_io = stub('UploadIO')
          expected_content_type = stub('Content Type')
          @file_hash[:type] = expected_content_type
          
          UploadIO.should_receive(:new).with(anything, expected_content_type, anything).and_return(upload_io)
          
          UploadableIO.new(@file_hash).to_upload_io.should == upload_io          
        end
        
        it "should get the file from the :tempfile key" do
          upload_io = stub('UploadIO')
          expected_file = stub('File')
          @file_hash[:tempfile] = expected_file
          
          UploadIO.should_receive(:new).with(expected_file, anything  , anything).and_return(upload_io)
          
          UploadableIO.new(@file_hash).to_upload_io.should == upload_io          
        end
      end
    end
  end  # describe UploadableIO
end # class