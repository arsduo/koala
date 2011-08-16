require 'faraday'
require 'faraday_stack'

module Koala
  class Response
    attr_reader :status, :body, :headers
    def initialize(status, body, headers)
      @status = status
      @body = body
      @headers = headers
    end
  end

  module HTTPService
    # common functionality for all HTTP services

    class << self
      attr_accessor :faraday_middleware, :faraday_options
    end

    @faraday_options ||= {}
    
    DEFAULT_MIDDLEWARE = Proc.new do |builder|
      builder.request :multipart
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end

    def self.server(options = {})
      server = "#{options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER}"
      server.gsub!(/\.facebook/, "-video.facebook") if options[:video]
      "#{options[:use_ssl] ? "https" : "http"}://#{options[:beta] ? "beta." : ""}#{server}"
    end

    def self.make_request(path, args, verb, options = {})
      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

      # turn all the keys to strings (Faraday has issues with symbols under 1.8.7) and resolve UploadableIOs
      params = args.inject({}) {|hash, kv| hash[kv.first.to_s] = kv.last.is_a?(UploadableIO) ? kv.last.to_upload_io : kv.last; hash}

      # figure out our options for this request
      http_options = {:params => (verb == "get" ? params : {})}.merge(faraday_options || {}).merge(options)
      http_options[:use_ssl] = true if args["access_token"] # require http if there's a token

      # set up our Faraday connection
      # we have to manually assign params to the URL or the
      conn = Faraday.new(server(http_options), http_options, &(faraday_middleware || DEFAULT_MIDDLEWARE))

      response = conn.send(verb, path, (verb == "post" ? params : {}))
      Koala::Response.new(response.status.to_i, response.body, response.headers)
    end

    def self.encode_params(param_hash)
      # unfortunately, we can't use to_query because that's Rails, not Ruby
      # if no hash (e.g. no auth token) return empty string
      # this is used mainly by the Batch API nowadays
      ((param_hash || {}).collect do |key_and_value|
        key_and_value[1] = MultiJson.encode(key_and_value[1]) unless key_and_value[1].is_a? String
        "#{key_and_value[0].to_s}=#{CGI.escape key_and_value[1]}"
      end).join("&")
    end
    
    # deprecations
    def self.always_use_ssl
      Koala::Utils.deprecate("HTTPService.always_use_ssl is now HTTPService.faraday_options[:use_ssl]; always_use_ssl will be removed in a future version.")
      faraday_options[:use_ssl]
    end

    def self.always_use_ssl=(value)
      Koala::Utils.deprecate("HTTPService.always_use_ssl is now HTTPService.faraday_options[:use_ssl]; always_use_ssl will be removed in a future version.")
      faraday_options[:use_ssl] = value
    end
    
    def self.timeout
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.faraday_options[:timeout]; .timeout will be removed in a future version.")
      faraday_options[:timeout]
    end

    def self.timeout=(value)
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.faraday_options[:timeout]; .timeout will be removed in a future version.")
      faraday_options[:timeout] = value
    end

  end
end