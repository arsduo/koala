require 'cgi'
require 'digest/md5'

require 'json'

# OpenSSL and Base64 are required to support signed_request
require 'openssl'
require 'base64'

# include koala modules
require 'koala/http_services'
require 'koala/oauth'
require 'koala/graph_api'
require 'koala/rest_api'
require 'koala/realtime_updates'
require 'koala/test_users'

# add KoalaIO class
require 'koala/uploadable_io'

module Koala

  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010 Facebook
    # Adapted from the Python library by Alex Koppel, Rafi Jacoby, and the team at Context Optional
    #
    # Licensed under the Apache License, Version 2.0 (the "License"); you may
    # not use this file except in compliance with the License. You may obtain
    # a copy of the License at
    #     http://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
    # WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
    # License for the specific language governing permissions and limitations
    # under the License.
    #
    # This client library is designed to support the Graph API and the official
    # Facebook JavaScript SDK, which is the canonical way to implement
    # Facebook authentication. Read more about the Graph API at
    # http://developers.facebook.com/docs/api. You can download the Facebook
    # JavaScript SDK at http://github.com/facebook/connect-js/.

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

        # Parse the body as JSON and check for errors if provided a mechanism to do so
        # Note: Facebook sometimes sends results like "true" and "false", which aren't strictly objects
        # and cause JSON.parse to fail -- so we account for that by wrapping the result in []
        body = response = JSON.parse("[#{result.body.to_s}]")[0]
        if error_checking_block
          yield(body)
        end

        # now return the desired information
        if options[:http_component]
          result.send(options[:http_component])
        else
          body
        end
      end
    end

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
