require 'koala/api/graph_api'
require 'koala/api/rest_api'
# graph_batch_api and legacy are required at the bottom, since they depend on API being defined

module Koala
  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010-2011 Alex Koppel
    # Contributors: Alex Koppel, Chris Baclig, Rafi Jacoby, and the team at Context Optional
    # http://github.com/arsduo/koala

    class API
      # Initializes a new API client.
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
      # @see GraphAPIMethods#graph_call
      # @see RestAPIMethods#rest_call
      # @param [String] path the server path for this request (leading / is prepended if not present)
      # @param [Hash] args arguments to be sent to Facebook for this request
      # @param [String] verb the HTTP method to use
      # @param [Hash] options request-related options for Koala and Faraday
      # @option options [Symbol] :http_component which part of the response (headers, body, or status) to return
      # @option options [Boolean] :beta use Facebook's beta tier
      # @option options [Boolean] :use_ssl force SSL for this request, even if it's tokenless (all APIs with tokens use SSL)
      # @note See https://github.com/arsduo/koala/wiki/HTTP-Services for additional HTTP options used by Faraday
      # @param [Proc] error_checking_block a block to evaluate the response status for additional JSON-encoded errors 
      # @yield [body] yields the response body for evaluation
      # @raise [Koala::Facebook::APIError] if Facebook returns an error (response status >= 500)      
      # @returns the body of the response from Facebook (unless another http_component is requested)
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
        # and cause MultiJson.decode to fail -- so we account for that by wrapping the result in []
        body = MultiJson.decode("[#{result.body.to_s}]")[0]
        yield body if error_checking_block

        # if we want a component other than the body (e.g. redirect header for images), return that
        options[:http_component] ? result.send(options[:http_component]) : body
      end
    end
    
    class APIError < StandardError
      attr_accessor :fb_error_type, :raw_response
      def initialize(details = {})
        self.raw_response = details
        self.fb_error_type = details["type"]
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  end
end

require 'koala/api/graph_batch_api'
# legacy support for old pre-1.2 API interfaces
require 'koala/api/legacy'