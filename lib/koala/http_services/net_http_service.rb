require "net/http" unless defined?(Net::HTTP)
require "net/https"
require "net/http/post/multipart"

module Koala
  module NetHTTPService
    # this service uses Net::HTTP to send requests to the graph
    include Koala::HTTPService

    # Net::HTTP-specific values
    class << self
      attr_accessor :ca_file, :ca_path, :verify_mode
    end
    
    def self.make_request(path, args, verb, options = {})
      # We translate args to a valid query string. If post is specified,
      # we send a POST request to the given path with the given arguments.

      # by default, we use SSL only for private requests
      # this makes public requests faster
      private_request = args["access_token"] || @always_use_ssl || options[:use_ssl]

      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

      http = create_http(server(options), private_request, options)

      response = http.start do |http|
        if verb == "post"
          if params_require_multipart? args
            http.request Net::HTTP::Post::Multipart.new path, encode_multipart_params(args)
          else
            http.post(path, encode_params(args))
          end
        else
          http.get("#{path}?#{encode_params(args)}")
        end
      end

      Koala::Response.new(response.code.to_i, response.body, response)
    end

    protected
    def self.encode_params(param_hash)
      # unfortunately, we can't use to_query because that's Rails, not Ruby
      # if no hash (e.g. no auth token) return empty string
      ((param_hash || {}).collect do |key_and_value|
        key_and_value[1] = MultiJson.encode(key_and_value[1]) if key_and_value[1].class != String
        "#{key_and_value[0].to_s}=#{CGI.escape key_and_value[1]}"
      end).join("&")
    end

    def self.encode_multipart_params(param_hash)
      Hash[*param_hash.collect do |key, value|
        [key, value.kind_of?(Koala::UploadableIO) ? value.to_upload_io : value]
      end.flatten]
    end

    def self.create_http(server, private_request, options)
      if proxy_server = options[:proxy] || proxy
        proxy = URI.parse(proxy_server)
        http  = Net::HTTP.new(server, private_request ? 443 : nil,
                              proxy.host, proxy.port, proxy.user, proxy.password)
      else
        http  = Net::HTTP.new(server, private_request ? 443 : nil)
      end

      if timeout_value = options[:timeout] || timeout
        http.open_timeout = timeout_value
        http.read_timeout = timeout_value
      end

      # For HTTPS requests, set the proper CA certificates
      if private_request
        http.use_ssl = true  
        http.verify_mode = options[:verify_mode] || verify_mode || OpenSSL::SSL::VERIFY_PEER
        
        if cert_file = options[:ca_file] || ca_file
          raise Errno::ENOENT, "Certificate file #{cert_file.inspect} does not exist!" unless File.exists?(cert_file)
          http.ca_file = cert_file 
        end
        
        if cert_path = options[:ca_path] || ca_path
          raise Errno::ENOENT, "Certificate path #{cert_path.inspect} does not exist!" unless File.directory?(cert_path)
          http.ca_path = cert_path
        end
      end

      http
    end
  end
end
