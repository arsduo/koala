require 'cgi'
require 'digest/md5'

require 'json'

# OpenSSL and Base64 are required to support signed_request
require 'openssl'
require 'base64'

# include koala modules
require 'koala/oauth'
require 'koala/graph_api'
require 'koala/rest_api'
require 'koala/realtime_updates'
require 'koala/test_users'
require 'koala/http_services'

# add KoalaIO class
require 'koala/uploadable_io'

module Koala

  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010-2011 Alex Koppel
    # Contributors: Alex Koppel, Chris Baclig, Rafi Jacoby, and the team at Context Optional
    # http://github.com/arsduo/koala

    class API
      # initialize with an access token
      def initialize(access_token = nil)
        @access_token = access_token
      end
      attr_reader :access_token

      def api(path, args = {}, verb = "get", options = {}, &post_processing)
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
        # and cause JSON.parse to fail -- so we account for that by wrapping the result in []
        body = JSON.parse("[#{result.body.to_s}]")[0]
        if error_checking_block = options[:error_checking_block]
          error_checking_block.call(body)
        end
        
        # if we want a compontent other than the body (e.g. redirect header for images), return that
        output = options[:http_component] ? result.send(options[:http_component]) : body
        
        post_processing ? post_processing.call(output) : output
      end

      def batch_api(batch_calls)
        # Get the access token for the user and start building a hash to store params
        args = {}
        args['access_token'] = @access_token || @app_access_token if @access_token || @app_access_token

        # Turn the call args collected into what facebook expects
        calls = batch_calls.map do |call|
          { 'method' => call[2], 'relative_url' => call[0], 'body' => call[1].map { |k, v| "#{k}=#{v}" }.join('&') }
        end
        args['batch'] = calls.to_json

        # Make the POST request for the batch call
        result = Koala.make_request('/', args, 'post')

        # Raise an error if we get a 500
        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status != 200

        # Map the results with post-processing included
        idx = 0 # keep compat with ruby 1.8 - no with_index for map
        JSON.parse(result.body.to_s).map do |result|
          # Get the options hash
          options = batch_calls[idx][3]
          idx += 1
          # Get the HTTP component they want
          if options[:http_component] == :headers
            data = {}
            result['headers'].each { |h| data[h['name']] = h['value'] }
          else
            body = result['body']
            data = body ? JSON::parse(body) : {}
          end
          # Process it if we are given a block to process with
          process_block = options[:process]
          process_block ? process_block.call(data) : data
        end
      end

    end

    # APIs

    class GraphAPI < API
      include GraphAPIMethods
    end

    class RestAPI < API
      include RestAPIMethods
    end

    class GraphAndRestAPI < API
      include GraphAPIMethods
      include RestAPIMethods
    end

    class RealtimeUpdates < API
      include RealtimeUpdateMethods
    end

    class TestUsers < API
      include TestUserMethods
      # make the Graph API accessible in case someone wants to make other calls to interact with their users
      attr_reader :graph_api
    end

    # Batch processing
    
    class BatchOperation
      def initialize(&action)
        raise KoalaError, "BatchOperation requires a proc containing the code to be executed in the batch!" unless action
        @action = action
      end
    end

    # Errors

    class APIError < StandardError
      attr_accessor :fb_error_type
      def initialize(details = {})
        self.fb_error_type = details["type"]
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  end

  class KoalaError< StandardError; end

  # finally, set up the http service Koala methods used to make requests
  # you can use your own (for HTTParty, etc.) by calling Koala.http_service = YourModule
  def self.http_service=(service)
    self.send(:include, service)
  end

  # by default, try requiring Typhoeus -- if that works, use it
  # if you have Typheous and don't want to use it (or want another service),
  # you can run Koala.http_service = NetHTTPService (or MyHTTPService)
  begin
    Koala.http_service = TyphoeusService
  rescue LoadError
    Koala.http_service = NetHTTPService
  end
end
