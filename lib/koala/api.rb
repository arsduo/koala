# graph_batch_api and legacy are required at the bottom, since they depend on API being defined
require 'koala/api/graph_api'
require 'koala/api/rest_api'

module Koala
  module Facebook
    class API
      # Creates a new API client.
      # @param [String] access_token access token
      # @note If no access token is provided, you can only access some public information.
      # @return [Koala::Facebook::API] the API client
      def initialize(access_token = nil)
        @access_token = access_token
      end

      attr_reader :access_token

      include GraphAPIMethods
      include RestAPIMethods

      # Makes a request to the appropriate Facebook API.
      # @note You'll rarely need to call this method directly.
      #
      # @see GraphAPIMethods#graph_call
      # @see RestAPIMethods#rest_call
      #
      # @param path the server path for this request (leading / is prepended if not present)
      # @param args arguments to be sent to Facebook
      # @param verb the HTTP method to use
      # @param options request-related options for Koala and Faraday.
      #                See https://github.com/arsduo/koala/wiki/HTTP-Services for additional options.
      # @option options [Symbol] :http_component which part of the response (headers, body, or status) to return
      # @option options [Boolean] :beta use Facebook's beta tier
      # @option options [Boolean] :use_ssl force SSL for this request, even if it's tokenless.
      #                                    (All API requests with access tokens use SSL.)
      # @param error_checking_block a block to evaluate the response status for additional JSON-encoded errors
      #
      # @yield The response body for evaluation
      #
      # @raise [Koala::Facebook::APIError] if Facebook returns an error (response status >= 500)
      #
      # @return the body of the response from Facebook (unless another http_component is requested)
      def api(path, args = {}, verb = "get", options = {}, &error_checking_block)
        # Fetches the given path in the Graph API.
        args["access_token"] = @access_token || @app_access_token if @access_token || @app_access_token

        # add a leading /
        path = "/#{path}" unless path =~ /^\//

        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)

        # Check for any 500 errors before parsing the body
        # since we're not guaranteed that the body is valid JSON
        # in the case of a server error
        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status >= 500

        # parse the body as JSON and run it through the error checker (if provided)
        # Note: Facebook sometimes sends results like "true" and "false", which aren't strictly objects
        # and cause MultiJson.load to fail -- so we account for that by wrapping the result in []
        body = MultiJson.load("[#{result.body.to_s}]")[0]
        yield body if error_checking_block

        # if we want a component other than the body (e.g. redirect header for images), return that
        if component = options[:http_component]
          component == :response ? result : result.send(options[:http_component])
        else
          body
        end
      end
    end

    class APIError < StandardError
      attr_accessor :fb_error_type, :fb_error_code, :fb_error_message, :raw_response

      # Creates a new APIError.
      #
      # Assigns the error type (as reported by Facebook) to #fb_error_type
      # and the raw error response available to #raw_response.
      #
      # @param details error details containing "type" and "message" keys.
      def initialize(details = {})
        self.raw_response = details
        self.fb_error_type = details["type"]
        self.fb_error_code = details["code"]
        self.fb_error_message = details["message"]
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  end
end

require 'koala/api/graph_batch_api'
# legacy support for old pre-1.2 API interfaces
require 'koala/api/legacy'