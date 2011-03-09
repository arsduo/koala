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
    def self.included(base)
      base.class_eval do
        class << self
          attr_accessor :always_use_ssl
        end
               
        def self.server(options = {})
          "#{options[:beta] ? "beta." : ""}#{options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER}"          
        end
                                      
        protected
        
        def self.params_require_multipart?(param_hash)
          param_hash.any? { |key, value| value.kind_of?(Koala::UploadableIO) }
        end
    
        def self.multipart_requires_content_type?
          true
        end
      end
    end
  end

  module NetHTTPService
    # this service uses Net::HTTP to send requests to the graph
    def self.included(base)
      base.class_eval do
        require "net/http" unless defined?(Net::HTTP)
        require "net/https"
        require "net/http/post/multipart"

        include Koala::HTTPService

        def self.make_request(path, args, verb, options = {})
          # We translate args to a valid query string. If post is specified,
          # we send a POST request to the given path with the given arguments.

          # by default, we use SSL only for private requests
          # this makes public requests faster
          private_request = args["access_token"] || @always_use_ssl || options[:use_ssl]

          # if the verb isn't get or post, send it as a post argument
          args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

          http = Net::HTTP.new(server(options), private_request ? 443 : nil)
          http.use_ssl = true if private_request

          # we turn off certificate validation to avoid the
          # "warning: peer certificate won't be verified in this SSL session" warning
          # not sure if this is the right way to handle it
          # see http://redcorundum.blogspot.com/2008/03/ssl-certificates-and-nethttps.html
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE

          result = http.start do |http|
            response, body = if verb == "post"
              if params_require_multipart? args
                http.request Net::HTTP::Post::Multipart.new path, encode_multipart_params(args)
              else
                http.post(path, encode_params(args))
              end
            else
              http.get("#{path}?#{encode_params(args)}")
            end
            
            Koala::Response.new(response.code.to_i, body, response)
          end
        end

        protected
        def self.encode_params(param_hash)
          # unfortunately, we can't use to_query because that's Rails, not Ruby
          # if no hash (e.g. no auth token) return empty string
          ((param_hash || {}).collect do |key_and_value|
            key_and_value[1] = key_and_value[1].to_json if key_and_value[1].class != String
            "#{key_and_value[0].to_s}=#{CGI.escape key_and_value[1]}"
          end).join("&")
        end
        
        def self.encode_multipart_params(param_hash)
          Hash[*param_hash.collect do |key, value| 
            [key, value.kind_of?(Koala::UploadableIO) ? value.to_upload_io : value]
          end.flatten]
        end
      end
    end
  end

  module TyphoeusService
    # this service uses Typhoeus to send requests to the graph

    def self.included(base)
      base.class_eval do
        require "typhoeus" unless defined?(Typhoeus)
        include Typhoeus
        
        include Koala::HTTPService

        def self.make_request(path, args, verb, options = {})
          # if the verb isn't get or post, send it as a post argument
          args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

          # you can pass arguments directly to Typhoeus using the :typhoeus_options key
          typhoeus_options = {:params => args}.merge(options[:typhoeus_options] || {})

          # by default, we use SSL only for private requests (e.g. with access token)
          # this makes public requests faster
          prefix = (args["access_token"] || @always_use_ssl || options[:use_ssl]) ? "https" : "http"

          response = self.send(verb, "#{prefix}://#{server(options)}#{path}", typhoeus_options)
          Koala::Response.new(response.code, response.body, response.headers_hash)
        end
        
        private
        def self.multipart_requires_content_type?
          false # Typhoeus handles multipart file types, we don't have to require it
        end
      end # class_eval
    end
  end
end