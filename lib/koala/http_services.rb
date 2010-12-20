module Koala
  class Response
    attr_reader :status, :body, :headers
    def initialize(status, body, headers)
      @status = status
      @body = body
      @headers = headers
    end
  end
  
  module NetHTTPService
    # this service uses Net::HTTP to send requests to the graph
    def self.included(base)
      base.class_eval do
        require "net/http" unless defined?(Net::HTTP)
        require "net/https"
        require "net/http/post/multipart"

        def self.make_request(path, args, verb, options = {})
          # We translate args to a valid query string. If post is specified,
          # we send a POST request to the given path with the given arguments.

          # if the verb isn't get or post, send it as a post argument
          args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

          server = options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER
          http = Net::HTTP.new(server, 443)
          http.use_ssl = true
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
        
        def self.params_require_multipart?(param_hash)
          param_hash.any? { |key, value| value.kind_of? File }
        end
        
        def self.encode_multipart_params(param_hash)
          Hash[*param_hash.collect do |key, value| 
            [key, value.kind_of?(File) ? UploadIO.new(value, infer_content_type(value)) : value]
          end.flatten]
        end
        
        # These are accepted image content types, pulled from the
        # Rest API photos.upload method.  If we begin to support
        # more file types (like when we allow videos) we may want to
        # consider refactoring this out into a separate class or
        # even depend on a third-party gem to infer content types
        def self.infer_content_type(file_or_name)
          ext = File.extname(file_or_name.kind_of?(File) ? file_or_name.path : file_or_name)
          
          case ext
            when ".gif" then "image/gif"
            when ".jpg", ".jpe", ".jpeg" then "image/jpeg"
            when ".png" then "image/png"
            when ".tiff", ".tif" then "image/tiff"
            when ".xbm" then "image/x-xbitmap"
            when ".wbmp" then "image/vnd.wap.wbmp"
            when ".iff" then "image/iff"
            when ".jp2" then "image/jp2"
            when ".psd" then "image/psd"
            else raise "#{ext} extension not supported by Koala::NetHTTPService"
          end
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

        def self.make_request(path, args, verb, options = {})
          # if the verb isn't get or post, send it as a post argument
          args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"
          server = options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER
          typhoeus_options = {:params => args}.merge(options[:typhoeus_options] || {})
          response = self.send(verb, "https://#{server}#{path}", typhoeus_options)
          Koala::Response.new(response.code, response.body, response.headers_hash)
        end
      end # class_eval
    end
  end
end