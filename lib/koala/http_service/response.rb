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

      def data
        @data ||= JSON.parse(body) unless body.empty?
      end
    end
  end
end
