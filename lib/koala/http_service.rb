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

    # Default servers for Facebook. These are read into the config OpenStruct,
    # and can be overridden via Koala.config.
    DEFAULT_SERVERS = {
      :graph_server => 'graph.facebook.com',
      :dialog_host => 'www.facebook.com',
      :rest_server => 'api.facebook.com',
      # certain Facebook services (beta, video) require you to access different
      # servers. If you're using your own servers, for instance, for a proxy,
      # you can change both the matcher and the replacement values.
      # So for instance, if you're talking to fbproxy.mycompany.com, you could
      # set up beta.fbproxy.mycompany.com for FB's beta tier, and set the
      # matcher to /\.fbproxy/ and the beta_replace to '.beta.fbproxy'.
      :host_path_matcher => /\.facebook/,
      :video_replace => '-video.facebook',
      :beta_replace => '.beta.facebook'
    }

    # The address of the appropriate Facebook server.
    #
    # @param options various flags to indicate which server to use.
    # @option options :rest_api use the old REST API instead of the Graph API
    # @option options :video use the server designated for video uploads
    # @option options :beta use the beta tier
    # @option options :use_ssl force https, even if not needed
    #
    # @return a complete server address with protocol
    def self.server(options = {})
      server = "#{options[:rest_api] ? Koala.config.rest_server : Koala.config.graph_server}"
      server.gsub!(Koala.config.host_path_matcher, Koala.config.video_replace) if options[:video]
      server.gsub!(Koala.config.host_path_matcher, Koala.config.beta_replace) if options[:beta]
      "#{options[:use_ssl] ? "https" : "http"}://#{server}"
    end

    # Makes a request directly to Facebook.
    # @note You'll rarely need to call this method directly.
    #
    # @see Koala::Facebook::API#api
    # @see Koala::Facebook::GraphAPIMethods#graph_call
    # @see Koala::Facebook::RestAPIMethods#rest_call
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

      # if an api_version is specified and the path does not already contain
      # one, prepend it to the path
      api_version = request_options[:api_version] || Koala.config.api_version
      if api_version && !path_contains_api_version?(path)
        begins_with_slash = path[0] == "/"
        divider = begins_with_slash ? "" : "/"
        path = "/#{api_version}#{divider}#{path}"
      end

      # set up our Faraday connection
      # we have to manually assign params to the URL or the
      conn = Faraday.new(server(request_options), faraday_options(request_options), &(faraday_middleware || DEFAULT_MIDDLEWARE))

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

    # Determines whether a given path already contains an API version.
    #
    # @param path the URL path.
    #
    # @return true or false accordingly.
    def self.path_contains_api_version?(path)
      match = /^\/?(v\d+(?:\.\d+)?)\//.match(path)
      !!(match && match[1])
    end

    private

    def self.faraday_options(options)
      valid_options = [:request, :proxy, :ssl, :builder, :url, :parallel_manager, :params, :headers, :builder_class]
      Hash[ options.select { |key,value| valid_options.include?(key) } ]
    end
  end
end
