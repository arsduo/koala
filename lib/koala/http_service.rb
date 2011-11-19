require 'faraday'
require 'koala/multipart_request'

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
    class << self

      attr_accessor :faraday_middleware, :http_options
    end

    @http_options ||= {}
    
    DEFAULT_MIDDLEWARE = Proc.new do |builder|
      builder.use Koala::MultipartRequest
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end

    def self.server(options = {})
      server = "#{options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER}"
      server.gsub!(/\.facebook/, "-video.facebook") if options[:video]
      server.gsub!(/\.facebook/, ".beta.facebook") if options[:beta]
      "#{options[:use_ssl] ? "https" : "http"}://#{server}"
    end

    def self.make_request(path, args, verb, options = {})
      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

      # turn all the keys to strings (Faraday has issues with symbols under 1.8.7) and resolve UploadableIOs
      params = args.inject({}) {|hash, kv| hash[kv.first.to_s] = kv.last.is_a?(UploadableIO) ? kv.last.to_upload_io : kv.last; hash}

      # figure out our options for this request   
      request_options = {:params => (verb == "get" ? params : {})}.merge(http_options || {}).merge(process_options(options))
      request_options[:use_ssl] = true if args["access_token"] # require http if there's a token

      # set up our Faraday connection
      # we have to manually assign params to the URL or the
      conn = Faraday.new(server(request_options), request_options, &(faraday_middleware || DEFAULT_MIDDLEWARE))

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
    # not elegant or compact code, but temporary
    
    def self.always_use_ssl
      Koala::Utils.deprecate("HTTPService.always_use_ssl is now HTTPService.http_options[:use_ssl]; always_use_ssl will be removed in a future version.")
      http_options[:use_ssl]
    end

    def self.always_use_ssl=(value)
      Koala::Utils.deprecate("HTTPService.always_use_ssl is now HTTPService.http_options[:use_ssl]; always_use_ssl will be removed in a future version.")
      http_options[:use_ssl] = value
    end
    
    def self.timeout
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.http_options[:timeout]; .timeout will be removed in a future version.")
      http_options[:timeout]
    end

    def self.timeout=(value)
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.http_options[:timeout]; .timeout will be removed in a future version.")
      http_options[:timeout] = value
    end
    
    def self.timeout
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.http_options[:timeout]; .timeout will be removed in a future version.")
      http_options[:timeout]
    end

    def self.timeout=(value)
      Koala::Utils.deprecate("HTTPService.timeout is now HTTPService.http_options[:timeout]; .timeout will be removed in a future version.")
      http_options[:timeout] = value
    end
    
    def self.proxy
      Koala::Utils.deprecate("HTTPService.proxy is now HTTPService.http_options[:proxy]; .proxy will be removed in a future version.")
      http_options[:proxy]
    end

    def self.proxy=(value)
      Koala::Utils.deprecate("HTTPService.proxy is now HTTPService.http_options[:proxy]; .proxy will be removed in a future version.")
      http_options[:proxy] = value
    end
    
    def self.ca_path
      Koala::Utils.deprecate("HTTPService.ca_path is now (HTTPService.http_options[:ssl] ||= {})[:ca_path]; .ca_path will be removed in a future version.")
      (http_options[:ssl] || {})[:ca_path]
    end

    def self.ca_path=(value)
      Koala::Utils.deprecate("HTTPService.ca_path is now (HTTPService.http_options[:ssl] ||= {})[:ca_path]; .ca_path will be removed in a future version.")
      (http_options[:ssl] ||= {})[:ca_path] = value
    end
    
    def self.ca_file
      Koala::Utils.deprecate("HTTPService.ca_file is now (HTTPService.http_options[:ssl] ||= {})[:ca_file]; .ca_file will be removed in a future version.")
      (http_options[:ssl] || {})[:ca_file]
    end

    def self.ca_file=(value)
      Koala::Utils.deprecate("HTTPService.ca_file is now (HTTPService.http_options[:ssl] ||= {})[:ca_file]; .ca_file will be removed in a future version.")
      (http_options[:ssl] ||= {})[:ca_file] = value
    end

    def self.verify_mode
      Koala::Utils.deprecate("HTTPService.verify_mode is now (HTTPService.http_options[:ssl] ||= {})[:verify_mode]; .verify_mode will be removed in a future version.")
      (http_options[:ssl] || {})[:verify_mode]
    end

    def self.verify_mode=(value)
      Koala::Utils.deprecate("HTTPService.verify_mode is now (HTTPService.http_options[:ssl] ||= {})[:verify_mode]; .verify_mode will be removed in a future version.")
      (http_options[:ssl] ||= {})[:verify_mode] = value
    end

    def self.process_options(options)
      if typhoeus_options = options.delete(:typhoeus_options)
        Koala::Utils.deprecate("typhoeus_options should now be included directly in the http_options hash.  Support for this key will be removed in a future version.")
        options = options.merge(typhoeus_options)
      end
      
      if ca_file = options.delete(:ca_file)
        Koala::Utils.deprecate("http_options[:ca_file] should now be passed inside (http_options[:ssl] = {}) -- that is, http_options[:ssl][:ca_file].  Support for this key will be removed in a future version.")
        (options[:ssl] ||= {})[:ca_file] = ca_file
      end

      if ca_path = options.delete(:ca_path)
        Koala::Utils.deprecate("http_options[:ca_path] should now be passed inside (http_options[:ssl] = {}) -- that is, http_options[:ssl][:ca_path].  Support for this key will be removed in a future version.")
        (options[:ssl] ||= {})[:ca_path] = ca_path
      end

      if verify_mode = options.delete(:verify_mode)
        Koala::Utils.deprecate("http_options[:verify_mode] should now be passed inside (http_options[:ssl] = {}) -- that is, http_options[:ssl][:verify_mode].  Support for this key will be removed in a future version.")
        (options[:ssl] ||= {})[:verify_mode] = verify_mode
      end
      
      options
    end   
  end
  
  module TyphoeusService
    def self.deprecated_interface
      # support old-style interface with a warning
      Koala::Utils.deprecate("the TyphoeusService module is deprecated; to use Typhoeus, set Faraday.default_adapter = :typhoeus.  Enabling Typhoeus for all Faraday connections.")
      Faraday.default_adapter = :typhoeus
    end
  end

  module NetHTTPService
    def self.deprecated_interface
      # support old-style interface with a warning
      Koala::Utils.deprecate("the NetHTTPService module is deprecated; to use Net::HTTP, set Faraday.default_adapter = :net_http.  Enabling Net::HTTP for all Faraday connections.")
      Faraday.default_adapter = :net_http
    end
  end
end