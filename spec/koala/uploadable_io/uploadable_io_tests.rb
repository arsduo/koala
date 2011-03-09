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
  
  VALID_PATH = File.join(File.dirname(__FILE__), "..", "assets", "beach.jpg")
  
  describe UploadableIO do
    shared_examples_for "MIME::Types can't return results" do
      {
        "jpg" => "image/jpeg",
        "jpeg" => "image/jpeg",
        "png" => "image/png", 
        "gif" => "image/gif"
      }.each_pair do |extension, mime_type|
        it "should properly get content types for #{extension} using basic analysis" do
          path = "filename.#{extension}"
          if @koala_io_params[0].is_a?(File)
            @koala_io_params[0].stub!(:path).and_return(path)
          else 
            @koala_io_params[0] = path
          end
          UploadableIO.new(*@koala_io_params).content_type.should == mime_type
        end

        it "should get content types for #{extension} using basic analysis with file names with more than one dot" do
          path = "file.name.#{extension}"
          if @koala_io_params[0].is_a?(File)
            @koala_io_params[0].stub!(:path).and_return(path)
          else 
            @koala_io_params[0] = path
          end
          UploadableIO.new(*@koala_io_params).content_type.should == mime_type
        end
      end

      describe "if the MIME type can't be determined" do
        before :each do
          path = "badfile.badextension"
          if @koala_io_params[0].is_a?(File)
            @koala_io_params[0].stub!(:path).and_return(path)
          else 
            @koala_io_params[0] = path
          end
        end

        it "should throw an exception if the MIME type can't be determined and the HTTP service requires content type" do
          Koala.stub!(:multipart_requires_content_type?).and_return(true)
          lambda { UploadableIO.new(*@koala_io_params) }.should raise_exception(KoalaError)  
        end

        it "should just have @content_type == nil if the HTTP service doesn't require content type" do
          Koala.stub!(:multipart_requires_content_type?).and_return(false)
          UploadableIO.new(*@koala_io_params).content_type.should be_nil
        end
      end
    end
    
    shared_examples_for "determining a mime type" do
      describe "if MIME::Types is available" do
        it "should return an UploadIO with MIME::Types-determined type if the type exists" do
          type_result = ["type"]
          Koala::MIME::Types.stub(:type_for).and_return(type_result)
          UploadableIO.new(*@koala_io_params).content_type.should == type_result.first          
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
    end    
    
    describe "the constructor" do      
      describe "when given a file path" do
        before(:each) do
          @koala_io_params = [
            File.open(VALID_PATH)
          ]
        end
        
        describe "and a content type" do
          before :each do
            @koala_io_params.concat([stub("image/jpg")])
          end
          
          it "should return an UploadIO with the same file path" do
            stub_path = @koala_io_params[0] = "/stub/path/to/file"              
            UploadableIO.new(*@koala_io_params).io_or_path.should == stub_path
          end
        
          it "should return an UploadIO with the same content type" do
            stub_type = @koala_io_params[1] = stub('Content Type')
            UploadableIO.new(*@koala_io_params).content_type.should == stub_type
          end
        end
        
        describe "and no content type" do
          it_should_behave_like "determining a mime type"
        end
      end
      
      describe "when given a File object" do
        before(:each) do
          @koala_io_params = [
            File.open(VALID_PATH)
          ]
        end
        
        describe "and a content type" do
          before :each do
            @koala_io_params.concat(["image/jpg"])
          end
          
          it "should return an UploadIO with the same io" do
            UploadableIO.new(*@koala_io_params).io_or_path.should == @koala_io_params[0]
          end
        
          it "should return an UplaodIO with the same content_type" do
            content_stub = @koala_io_params[1] = stub('Content Type')
            UploadableIO.new(*@koala_io_params).content_type.should == content_stub
          end
        end
        
        describe "and no content type" do
          it_should_behave_like "determining a mime type"
        end
      end
      
      describe "when given a Rails 3 ActionDispatch::Http::UploadedFile" do
        before(:each) do
          @tempfile = stub('Tempfile', :path => true)
          @uploaded_file = stub('ActionDispatch::Http::UploadedFile', 
            :content_type => true,
            :tempfile => @tempfile
          )

          @uploaded_file.stub!(:respond_to?).with(:path).and_return(true)
          @uploaded_file.stub!(:respond_to?).with(:content_type).and_return(true)
          @uploaded_file.stub!(:respond_to?).with(:tempfile).and_return(@tempfile)
          @tempfile.stub!(:respond_to?).with(:path).and_return(true)
        end
        
        it "should get the content type via the content_type method" do
          expected_content_type = stub('Content Type')
          @uploaded_file.should_receive(:content_type).and_return(expected_content_type)
          UploadableIO.new(@uploaded_file).content_type.should == expected_content_type
        end
        
        it "should get the path from the tempfile associated with the UploadedFile" do
          expected_path = stub('Tempfile')
          @tempfile.should_receive(:path).and_return(expected_path)
          UploadableIO.new(@uploaded_file).io_or_path.should == expected_path          
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
          expected_content_type = stub('Content Type')
          @file_hash[:type] = expected_content_type
          
          uploadable = UploadableIO.new(@file_hash)
          uploadable.content_type.should == expected_content_type          
        end
        
        it "should get the io_or_path from the :tempfile key" do
          expected_file = stub('File')
          @file_hash[:tempfile] = expected_file
                    
          uploadable = UploadableIO.new(@file_hash)
          uploadable.io_or_path.should == expected_file
        end
      end

      describe "for files with with recognizable MIME types" do
        # what that means is tested below
        it "should accept a file object alone" do
          params = [
            VALID_PATH
          ]
          lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
        end
        
        it "should accept a file path alone" do
          params = [
            VALID_PATH
          ]
          lambda { UploadableIO.new(*params) }.should_not raise_exception(KoalaError)
        end
      end
    end
          
    describe "getting an UploadableIO" do
      before(:each) do
        @upload_io = stub("UploadIO")
        UploadIO.stub!(:new).with(anything, anything, anything).and_return(@upload_io)
      end
      
      it "should call the constructor with the content type, file name, and a dummy file name" do
        UploadIO.should_receive(:new).with(VALID_PATH, "content/type", anything).and_return(@upload_io)
        UploadableIO.new(VALID_PATH, "content/type").to_upload_io.should == @upload_io        
      end
    end
    
    describe "getting a file" do
      it "should return the File if initialized with a file" do
        f = File.new(VALID_PATH)
        UploadableIO.new(f).to_file.should == f
      end
      
      it "should open up and return a file corresponding to the path if io_or_path is a path" do
        path = VALID_PATH
        result = stub("File")
        File.should_receive(:open).with(path).and_return(result)
        UploadableIO.new(path).to_file.should == result
      end
    end
  end  # describe UploadableIO
end # class