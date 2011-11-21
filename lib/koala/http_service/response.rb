module Koala
  module HTTPService
    class Response
      attr_reader :status, :body, :headers

      # Creates a new Response object, which standardizes the response received by Facebook for use within Koala.
      def initialize(status, body, headers)
        @status = status
        @body = body
        @headers = headers
      end
    end
  end
  
  # @private
  # legacy support for when Response lived directly under Koala
  Response = HTTPService::Response
end
