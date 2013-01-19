require 'faraday'
require 'koala/http_service/multipart_request'
require 'koala/http_service/uploadable_io'
require 'koala/http_service/response'

module Koala
  module HTTPService
    class << self
      # A customized stack of Faraday middleware that will be used to make each request.
      attr_accessor :faraday_middleware
      # A default set of HTTP options (see https://github.com/arsduo/koala/wiki/HTTP-Services)
      attr_accessor :http_options
    end

    @http_options ||= {}

    # Koala's default middleware stack.
    # We encode requests in a Facebook-compatible multipart request,
    # and use whichever adapter has been configured for this application.
    DEFAULT_MIDDLEWARE = Proc.new do |builder|
      builder.use Koala::HTTPService::MultipartRequest
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end

    # The address of the appropriate Facebook server.
    #
    # @param options various flags to indicate which server to use.
    # @option options :video use the server designated for video uploads
    # @option options :beta use the beta tier
    # @option options :use_ssl force https, even if not needed
    #
    # @return a complete server address with protocol
    def self.server(options = {})
      server = "http#{options[:use_ssl] ? "s" : ""}://#{Facebook::GRAPH_SERVER}"
      server.gsub!(/\.facebook/, "-video.facebook") if options[:video]
      server.gsub!(/\.facebook/, ".beta.facebook") if options[:beta]
      server
    end

    # Makes a request directly to Facebook.
    # @note You'll rarely need to call this method directly.
    #
    # @see Koala::Facebook::API#api
    # @see Koala::Facebook::GraphAPIMethods#graph_call
    #
    # @param path the server path for this request
    # @param args (see Koala::Facebook::API#api)
    # @param verb the HTTP method to use.
    #             If not get or post, this will be turned into a POST request with the appropriate :method
    #             specified in the arguments.
    # @param options (see Koala::Facebook::API#api)
    #
    # @raise an appropriate connection error if unable to make the request to Facebook
    #
    # @return [Koala::HTTPService::Response] a response object representing the results from Facebook
    def self.make_request(path, args, verb, options = {})
      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

      # turn all the keys to strings (Faraday has issues with symbols under 1.8.7) and resolve UploadableIOs
      params = args.inject({}) {|hash, kv| hash[kv.first.to_s] = kv.last.is_a?(UploadableIO) ? kv.last.to_upload_io : kv.last; hash}

      # figure out our options for this request
      request_options = {:params => (verb == "get" ? params : {})}.merge(http_options || {}).merge(options)
      request_options[:use_ssl] = true if args["access_token"] # require https if there's a token
      if request_options[:use_ssl]
        ssl = (request_options[:ssl] ||= {})
        ssl[:verify] = true unless ssl.has_key?(:verify)
      end

      # set up our Faraday connection
      # we have to manually assign params to the URL or the
      conn = Faraday.new(server(request_options), request_options, &(faraday_middleware || DEFAULT_MIDDLEWARE))

      response = conn.send(verb, path, (verb == "post" ? params : {}))

      # Log URL information
      Koala::Utils.debug "#{verb.upcase}: #{path} params: #{params.inspect}"
      Koala::HTTPService::Response.new(response.status.to_i, response.body, response.headers)
    end

    # Encodes a given hash into a query string.
    # This is used mainly by the Batch API nowadays, since Faraday handles this for regular cases.
    #
    # @param params_hash a hash of values to CGI-encode and appropriately join
    #
    # @example
    #   Koala.http_service.encode_params({:a => 2, :b => "My String"})
    #   => "a=2&b=My+String"
    #
    # @return the appropriately-encoded string
    def self.encode_params(param_hash)
      ((param_hash || {}).sort_by{|k, v| k.to_s}.collect do |key_and_value|
        key_and_value[1] = MultiJson.dump(key_and_value[1]) unless key_and_value[1].is_a? String
        "#{key_and_value[0].to_s}=#{CGI.escape key_and_value[1]}"
      end).join("&")
    end
  end
end
