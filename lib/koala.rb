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
  end

  # @private
  # For current HTTPServices, switch the service as expected.
  # For deprecated services (Typhoeus and Net::HTTP), print a warning and set the default Faraday adapter appropriately.
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

  # An convenenient alias to Koala.http_service.make_request. 
  def self.make_request(path, args, verb, options = {})
    http_service.make_request(path, args, verb, options)
  end

  # we use Faraday as our main service, with mock as the other main one
  self.http_service = HTTPService
end
