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
        # and cause JSON.parse to fail -- so we account for that by wrapping the result in []
        body = JSON.parse("[#{result.body.to_s}]")[0]
        yield body if error_checking_block

        # if we want a component other than the body (e.g. redirect header for images), return that
        options[:http_component] ? result.send(options[:http_component]) : body
      end
    end

    # APIs
    
    class GraphAPI < API
      include GraphAPIMethods

      def self.check_response(response)
        # check for Graph API-specific errors
        # this returns an error, which is immediately raised (non-batch)
        # or added to the list of batch results (batch)
        if response.is_a?(Hash) && error_details = response["error"]
          APIError.new(error_details) 
        end
      end

      # batch mode flags
      def self.batch_mode?
        !!@batch_mode
      end

      def self.batch_calls
        raise KoalaError, "GraphAPI.batch_calls accessed when not in batch block!" unless batch_mode?
        @batch_calls
      end

      def self.batch(&block)
        @batch_mode = true
        @batch_calls = []
        yield
        begin
          results = batch_api(@batch_calls)
        ensure
          @batch_mode = false
        end
        results
      end
      
      def self.batch_api(batch_calls)
        # Get the access token for the user and start building a hash to store params
        args = {}
        use_ssl = false
        
        # Turn the call args collected into what facebook expects
        args['batch'] = batch_calls.map { |call|
          # need to support binary files
          # if any component has an access token, we need to use ssl
          body = call[1].map { |k, v| use_ssl ||= (k.to_s == "access_token"); "#{k}=#{v}" }.join('&')
          { 'method' => call[2], 'relative_url' => call[0], 'body' => body}
        }
        args['batch'] = args['batch'].to_json
        
        # Make the POST request for the batch call
        result = Koala.make_request('/', args, 'post', :use_ssl => use_ssl)

        # Raise an error if we get a 500
        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status != 200

        # Map the results with post-processing included
        index = 0 # keep compat with ruby 1.8 - no with_index for map
        JSON.parse(result.body.to_s).map do |result|
          # Get the options hash
          options = batch_calls[index][3]
          index += 1

          # (see note in API about JSON parsing)
          body = JSON.parse("[#{result['body'].to_s}]")[0]
          unless error = check_response(body)
            # Get the HTTP component they want
            data = options[:http_component] != :headers ? body : \
              # facebook returns the headers as an array of k/v pairs, but we want a regular hash
              result['headers'].inject({}) { |headers, h| headers[h['name']] = h['value']; headers}
          
            # process it if we are given a block to process with
            post_processing = options[:post_processing]
            post_processing ? post_processing.call(data) : data
          else
            error
          end
        end
      end
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
