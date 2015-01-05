# graph_batch_api and legacy are required at the bottom, since they depend on API being defined
require 'koala/api/graph_api'
require 'koala/api/rest_api'
require 'openssl'

module Koala
  module Facebook
    class API
      # Creates a new API client.
      # @param [String] access_token access token
      # @param [String] app_secret app secret, for tying your access tokens to your app secret
      #                 If you provide an app secret, your requests will be
      #                 signed by default, unless you pass appsecret_proof:
      #                 false as an option to the API call. (See
      #                 https://developers.facebook.com/docs/graph-api/securing-requests/)
      # @note If no access token is provided, you can only access some public information.
      # @return [Koala::Facebook::API] the API client
      def initialize(access_token = nil, app_secret = nil)
        @access_token = access_token
        @app_secret = app_secret
      end

      attr_reader :access_token, :app_secret

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
      # @yield The response for evaluation
      #
      # @raise [Koala::Facebook::ServerError] if Facebook returns an error (response status >= 500)
      #
      # @return the body of the response from Facebook (unless another http_component is requested)
      def api(path, args = {}, verb = "get", options = {}, &error_checking_block)
        # we make a copy of args so the modifications (added access_token & appsecret_proof)
        # do not affect the received argument
        args = args.dup

        # If a access token is explicitly provided, use that
        # This is explicitly needed in batch requests so GraphCollection
        # results preserve any specific access tokens provided
        args["access_token"] ||= @access_token || @app_access_token if @access_token || @app_access_token
        if options.delete(:appsecret_proof) && args["access_token"] && @app_secret
          args["appsecret_proof"] = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @app_secret, args["access_token"])
        end

        # Translate any arrays in the params into comma-separated strings
        args = sanitize_request_parameters(args)

        # add a leading / if needed...
        path = "/#{path}" unless path =~ /^\//

        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)

        if result.status.to_i >= 500
          raise Koala::Facebook::ServerError.new(result.status.to_i, result.body)
        end

        yield result if error_checking_block

        # if we want a component other than the body (e.g. redirect header for images), return that
        if component = options[:http_component]
          component == :response ? result : result.send(options[:http_component])
        else
          # parse the body as JSON and run it through the error checker (if provided)
          # Note: Facebook sometimes sends results like "true" and "false", which aren't strictly objects
          # and cause MultiJson.load to fail -- so we account for that by wrapping the result in []
          MultiJson.load("[#{result.body.to_s}]")[0]
        end
      end

      private

      # Sanitizes Ruby objects into Facebook-compatible string values.
      #
      # @param parameters a hash of parameters.
      #
      # Returns a hash in which values that are arrays of non-enumerable values
      #         (Strings, Symbols, Numbers, etc.) are turned into comma-separated strings.
      def sanitize_request_parameters(parameters)
        parameters.reduce({}) do |result, (key, value)|
          # if the parameter is an array that contains non-enumerable values,
          # turn it into a comma-separated list
          # in Ruby 1.8.7, strings are enumerable, but we don't care
          if value.is_a?(Array) && value.none? {|entry| entry.is_a?(Enumerable) && !entry.is_a?(String)}
            value = value.join(",")
          end
          result.merge(key => value)
        end
      end
    end
  end
end

require 'koala/api/graph_batch_api'