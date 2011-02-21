require 'koala'

module Koala
  class UploadableIO
    def initialize(io_or_path_or_mixed, content_type = nil)
      if content_type.nil?
        parse_init_mixed_param io_or_path_or_mixed
      elsif !content_type.nil? && (io_or_path_or_mixed.respond_to?(:read) or io_or_path_or_mixed.kind_of?(String))
        @io_or_path = io_or_path_or_mixed
        @content_type = content_type
      else
        raise KoalaError.new("Invalid arguments to initialize an UploadableIO")
      end
    end
    
    def to_upload_io
      UploadIO.new(@io_or_path, @content_type, "koala-io-file.dum")
    end
    
    private
      PARSE_STRATEGIES = [
        :parse_rails_3_post_param
      ]
      
      def parse_init_mixed_param(mixed)
        PARSE_STRATEGIES.each do |method|
          return if send(method, mixed) 
        end
      end
      
      # Expects a parameter of type ActionDispatch::Http::UploadedFile
      def parse_rails_3_post_param(uploaded_file)
        if uploaded_file.respond_to?(:content_type) and uploaded_file.respond_to?(:tempfile) and uploaded_file.tempfile.respond_to?(:path)
          
          @io_or_path = uploaded_file.tempfile.path
          @content_type = uploaded_file.content_type
        end
      end
  end
end