require 'koala'

module Koala
  class UploadableIO
    def initialize(io_or_path, content_type = nil)
      if content_type and (io_or_path.respond_to?(:read) or io_or_path.kind_of?(String))
        @io_or_path = io_or_path
        @content_type = content_type
      else
        raise KoalaError.new("Invalid arguments to initialize an UploadableIO")
      end
    end

    def to_upload_io
      UploadIO.new(@io_or_path, @content_type, "koala-io-file.dum")
    end
  end
end