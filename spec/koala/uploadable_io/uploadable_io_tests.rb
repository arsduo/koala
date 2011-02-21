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
    end
  end  # describe UploadableIO
end # class