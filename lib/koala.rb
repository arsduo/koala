# useful tools
require 'digest/md5'
require 'multi_json'

# include koala modules
require 'koala/errors'
require 'koala/api'
require 'koala/oauth'
require 'koala/realtime_updates'
require 'koala/test_users'

# HTTP module so we can communicate with Facebook
require 'koala/http_service'

# miscellaneous
require 'koala/utils'
require 'koala/version'
require 'ostruct'

module Koala
  # A Ruby client library for the Facebook Platform.
  # See http://github.com/arsduo/koala/wiki for a general introduction to Koala
  # and the Graph API.

  # Making HTTP requests
  class << self
    # Control which HTTP service framework Koala uses.
    # Primarily used to switch between the mock-request framework used in testing
    # and the live framework used in real life (and live testing).
    # In theory, you could write your own HTTPService module if you need different functionality,
    # but since the switch to {https://github.com/arsduo/koala/wiki/HTTP-Services Faraday} almost all such goals can be accomplished with middleware.
    attr_accessor :http_service

    def configure
      yield config
    end

    # Allows you to control various Koala configuration options.
    # Notable options:
    #   * server endpoints: you can override any or all the server endpoints
    #   (see HTTPService::DEFAULT_SERVERS) if you want to run requests through
    #   other servers.
    #   * api_version: controls which Facebook API version to use (v1.0, v2.0,
    #   etc)
    def config
      @config ||= OpenStruct.new(HTTPService::DEFAULT_SERVERS)
    end

    # Used for testing.
    def reset_config
      @config = nil
    end
  end

  # @private
  # Switch the HTTP service -- mostly used for testing.
  def self.http_service=(service)
    # if it's a real http_service, use it
    @http_service = service
  end

  # An convenenient alias to Koala.http_service.make_request.
  def self.make_request(path, args, verb, options = {})
    http_service.make_request(path, args, verb, options)
  end

  # we use Faraday as our main service, with mock as the other main one
  self.http_service = HTTPService
end
