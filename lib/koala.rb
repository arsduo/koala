require 'cgi'
require 'digest/md5'

require 'multi_json'

# OpenSSL and Base64 are required to support signed_request
require 'openssl'
require 'base64'

# include koala modules
require 'koala/oauth'
require 'koala/graph_api'
require 'koala/graph_batch_api'
require 'koala/batch_operation'
require 'koala/graph_collection'
require 'koala/rest_api'
require 'koala/realtime_updates'
require 'koala/test_users'

# HTTP module so we can communicate with Facebook
require 'koala/http_service'
require 'koala/multipart_request'

# add KoalaIO class
require 'koala/uploadable_io'

# miscellaneous
require 'koala/utils'
require 'koala/version'

module Koala

  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010-2011 Alex Koppel
    # Contributors: Alex Koppel, Chris Baclig, Rafi Jacoby, and the team at Context Optional
    # http://github.com/arsduo/koala

    # APIs
    class API
      # initialize with an access token
      def initialize(access_token = nil)
        @access_token = access_token
      end
      attr_reader :access_token

      include GraphAPIMethods
      include RestAPIMethods

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
        if component = options[:http_component]
          component == :response ? result : result.send(options[:http_component])
        else
          body
        end
      end
    end

    # special enhanced APIs
    class GraphBatchAPI < API
      include GraphBatchAPIMethods
    end

    class RealtimeUpdates
      include RealtimeUpdateMethods
    end

    class TestUsers
      include TestUserMethods
    end

    # legacy support for old APIs
    class OldAPI < API;
      def initialize(*args)
        Koala::Utils.deprecate("#{self.class.name} is deprecated and will be removed in a future version; please use the API class instead.")
        super
      end
    end
    class GraphAPI < OldAPI; end
    class RestAPI < OldAPI; end
    class GraphAndRestAPI < OldAPI; end

    # Errors

    class APIError < StandardError
      attr_accessor :fb_error_type, :raw_response
      def initialize(details = {})
        self.raw_response = details
        self.fb_error_type = details["type"]
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  end

  class KoalaError < StandardError; end


  # finally, the few things defined on the Koala module itself
  class << self
    attr_accessor :http_service
  end

  def self.http_service=(service)
    if service.respond_to?(:deprecated_interface)
      # if this is a deprecated module, support the old interface
      # by changing the default adapter so the right library is used
      # we continue to use the single HTTPService module for everything
      service.deprecated_interface 
    else
      # if it's a real http_service, use it
      @http_service = service
    end
  end

  def self.make_request(path, args, verb, options = {})
    http_service.make_request(path, args, verb, options)
  end

  # we use Faraday as our main service, with mock as the other main one
  self.http_service = HTTPService
end
