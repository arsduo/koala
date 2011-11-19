# useful tools
require 'digest/md5'
require 'multi_json'

# include koala modules
require 'koala/api'
require 'koala/oauth'
require 'koala/realtime_updates'
require 'koala/test_users'

# HTTP module so we can communicate with Facebook
require 'koala/http_service'

# miscellaneous
require 'koala/utils'
require 'koala/version'

# @author Alex Koppel
module Koala
  class KoalaError < StandardError; end

  # Making HTTP requests
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
