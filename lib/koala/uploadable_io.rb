require 'koala'

module Koala
  class UploadableIO
    attr_reader :io_or_path, :content_type

    def initialize(io_or_path_or_mixed, content_type = nil)
      # see if we got the right inputs
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
        :parse_rails_3_param,
        :parse_sinatra_param,
        :parse_file_object,
        :parse_string_path
      ]
      
      def parse_init_mixed_param(mixed)
        PARSE_STRATEGIES.each do |method|
          send(method, mixed)
          return if @io_or_path && @content_type
        end
      end
      
      # Expects a parameter of type ActionDispatch::Http::UploadedFile
      def parse_rails_3_param(uploaded_file)
        if uploaded_file.respond_to?(:content_type) and uploaded_file.respond_to?(:tempfile) and uploaded_file.tempfile.respond_to?(:path)
          @io_or_path = uploaded_file.tempfile.path
          @content_type = uploaded_file.content_type
        end
      end
      
      # Expects a Sinatra hash of file info
      def parse_sinatra_param(file_hash)
        if file_hash.kind_of?(Hash) and file_hash.has_key?(:type) and file_hash.has_key?(:tempfile)
          @io_or_path = file_hash[:tempfile]
          @content_type = file_hash[:type] || detect_mime_type(tempfile)
        end
      end
      
      # takes a file object
      def parse_file_object(file)
        if file.kind_of?(File)
          @io_or_path = file
          @content_type = detect_mime_type(file.path)
        end
      end
      
      def parse_string_path(path)
        if path.kind_of?(String)
          @io_or_path = path
          @content_type = detect_mime_type(path)
        end
      end
      
      MIME_TYPE_STRATEGIES = [
        :use_mime_module,
        :use_simple_detection
      ]
      
      def detect_mime_type(filename)
        if filename
          MIME_TYPE_STRATEGIES.each do |method|
            result = send(method, filename)
            return result if result
          end
        end
        raise KoalaError, "UploadableIO unable to determine MIME type for #{filename}"
      end
      
      def use_mime_module(filename)
        # if the user has installed mime/types, we can use that
        # if not, rescue and return nil
        begin
          type = MIME::Types.type_for(filename).first
          type ? type.to_s : nil
        rescue
          nil
        end
      end
      
      def use_simple_detection(filename)
        # very rudimentary extension analysis for images
        # first, get the downcased extension, or an empty string if it doesn't exist
        extension = ((filename.match(/\.([a-zA-Z0-9]+)$/) || [])[1] || "").downcase
        if extension == ""
          nil
        elsif extension == "jpg" || extension == "jpeg"
          "image/jpeg"
        elsif extension == "png"
          "image/png"
        elsif extension == "gif"
          "image/gif"
        end
      end
  end
end