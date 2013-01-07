# fake MIME::Types
module Koala::MIME
  module Types
    def self.type_for(type)
      # this should be faked out in tests
      nil
    end
  end
end

describe "Koala::UploadableIO" do
  def rails_3_mocks
    tempfile = stub('Tempfile', :path => "foo")
    uploaded_file = stub('ActionDispatch::Http::UploadedFile',
      :content_type => true,
      :tempfile => tempfile,
      :original_filename => "bar"
    )
    tempfile.stub!(:respond_to?).with(:path).and_return(true)

    [tempfile, uploaded_file]
  end

  def sinatra_mocks
    {:type => "type", :tempfile => "Tempfile", :filename => "foo.bar"}
  end

  describe "the constructor" do
    describe "when given a file path" do
      before(:each) do
        @path = BEACH_BALL_PATH
        @koala_io_params = [@path]
      end

      describe "and a content type" do
        before :each do
          @stub_type = stub("image/jpg")
          @koala_io_params.concat([@stub_type])
        end

        it "returns an UploadIO with the same file path" do
          Koala::UploadableIO.new(*@koala_io_params).io_or_path.should == @path
        end

        it "returns an UploadIO with the same content type" do
          Koala::UploadableIO.new(*@koala_io_params).content_type.should == @stub_type
        end

        it "returns an UploadIO with the file's name" do
          Koala::UploadableIO.new(*@koala_io_params).filename.should == File.basename(@path)
        end
      end

      describe "and no content type" do
        it_should_behave_like "determining a mime type"
      end
    end

    describe "when given a File object" do
      before(:each) do
        @file = File.open(BEACH_BALL_PATH)
        @koala_io_params = [@file]
      end

      describe "and a content type" do
        before :each do
          @koala_io_params.concat(["image/jpg"])
        end

        it "returns an UploadIO with the same io" do
          Koala::UploadableIO.new(*@koala_io_params).io_or_path.should == @koala_io_params[0]
        end

        it "returns an UploadableIO with the same content_type" do
          content_stub = @koala_io_params[1] = stub('Content Type')
          Koala::UploadableIO.new(*@koala_io_params).content_type.should == content_stub
        end

        it "returns an UploadableIO with the right filename" do
          Koala::UploadableIO.new(*@koala_io_params).filename.should == File.basename(@file.path)
        end
      end

      describe "and no content type" do
        it_should_behave_like "determining a mime type"
      end
    end

    describe "when given an IO object" do
      before(:each) do
        @io = StringIO.open("abcdefgh")
        @koala_io_params = [@io]
      end

      describe "and a content type" do
        before :each do
          @koala_io_params.concat(["image/jpg"])
        end

        it "returns an UploadableIO with the same io" do
          Koala::UploadableIO.new(*@koala_io_params).io_or_path.should == @koala_io_params[0]
        end

        it "returns an UploadableIO with the same content_type" do
          content_stub = @koala_io_params[1] = stub('Content Type')
          Koala::UploadableIO.new(*@koala_io_params).content_type.should == content_stub
        end
      end

      describe "and no content type" do
        it "raises an exception" do
          lambda { Koala::UploadableIO.new(*@koala_io_params) }.should raise_exception(Koala::KoalaError)
        end
      end
    end

    describe "when given a Rails 3 ActionDispatch::Http::UploadedFile" do
      before(:each) do
        @tempfile, @uploaded_file = rails_3_mocks
      end

      it "gets the path from the tempfile associated with the UploadedFile" do
        expected_path = stub('Tempfile')
        @tempfile.should_receive(:path).and_return(expected_path)
        Koala::UploadableIO.new(@uploaded_file).io_or_path.should == expected_path
      end

      it "gets the content type via the content_type method" do
        expected_content_type = stub('Content Type')
        @uploaded_file.should_receive(:content_type).and_return(expected_content_type)
        Koala::UploadableIO.new(@uploaded_file).content_type.should == expected_content_type
      end

      it "gets the filename from the UploadedFile" do
        Koala::UploadableIO.new(@uploaded_file).filename.should == @uploaded_file.original_filename
      end
    end

    describe "when given a Sinatra file parameter hash" do
      before(:each) do
        @file_hash = sinatra_mocks
      end

      it "gets the io_or_path from the :tempfile key" do
        expected_file = stub('File')
        @file_hash[:tempfile] = expected_file

        uploadable = Koala::UploadableIO.new(@file_hash)
        uploadable.io_or_path.should == expected_file
      end

      it "gets the content type from the :type key" do
        expected_content_type = stub('Content Type')
        @file_hash[:type] = expected_content_type

        uploadable = Koala::UploadableIO.new(@file_hash)
        uploadable.content_type.should == expected_content_type
      end

      it "gets the content type from the :type key" do
        uploadable = Koala::UploadableIO.new(@file_hash)
        uploadable.filename.should == @file_hash[:filename]
      end
    end

    describe "for files with with recognizable MIME types" do
      # what that means is tested below
      it "should accept a file object alone" do
        params = [BEACH_BALL_PATH]
        lambda { Koala::UploadableIO.new(*params) }.should_not raise_exception(Koala::KoalaError)
      end

      it "should accept a file path alone" do
        params = [BEACH_BALL_PATH]
        lambda { Koala::UploadableIO.new(*params) }.should_not raise_exception(Koala::KoalaError)
      end
    end
  end

  describe "getting an UploadableIO" do
    before(:each) do
      @upload_io = stub("UploadIO")
      UploadIO.stub!(:new).with(anything, anything, anything).and_return(@upload_io)
    end

    context "if no filename was provided" do
      it "should call the constructor with the content type, file name, and a dummy file name" do
        UploadIO.should_receive(:new).with(BEACH_BALL_PATH, "content/type", anything).and_return(@upload_io)
        Koala::UploadableIO.new(BEACH_BALL_PATH, "content/type").to_upload_io.should == @upload_io
      end
    end

    context "if a filename was provided" do
      it "should call the constructor with the content type, file name, and the filename" do
        filename = "file"
        UploadIO.should_receive(:new).with(BEACH_BALL_PATH, "content/type", filename).and_return(@upload_io)
        Koala::UploadableIO.new(BEACH_BALL_PATH, "content/type", filename).to_upload_io
      end
    end
  end

  describe "getting a file" do
    it "returns the File if initialized with a file" do
      f = File.new(BEACH_BALL_PATH)
      Koala::UploadableIO.new(f).to_file.should == f
    end

    it "should open up and return a file corresponding to the path if io_or_path is a path" do
      result = stub("File")
      File.should_receive(:open).with(BEACH_BALL_PATH).and_return(result)
      Koala::UploadableIO.new(BEACH_BALL_PATH).to_file.should == result
    end
  end

  describe ".binary_content?" do
    it "returns true for Rails 3 file uploads" do
      Koala::UploadableIO.binary_content?(rails_3_mocks.last).should be_true
    end

    it "returns true for Sinatra file uploads" do
      Koala::UploadableIO.binary_content?(rails_3_mocks.last).should be_true
    end

    it "returns true for File objects" do
      Koala::UploadableIO.binary_content?(File.open(BEACH_BALL_PATH)).should be_true
    end

    it "returns false for everything else" do
      Koala::UploadableIO.binary_content?(StringIO.new).should be_false
      Koala::UploadableIO.binary_content?(BEACH_BALL_PATH).should be_false
      Koala::UploadableIO.binary_content?(nil).should be_false
    end
  end
end  # describe UploadableIO
