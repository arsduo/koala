module Koala
  module NetHTTPService
    # this service uses Net::HTTP to send requests to the graph
    def self.included(base)
      base.class_eval do
        require 'net/http' unless defined?(Net::HTTP)
        require 'net/https'

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

          result = http.start { |http|
            response, body = (verb == "post" ? http.post(path, encode_params(args)) : http.get("#{path}?#{encode_params(args)}")) 
            body
          }
        end

        protected
        def self.encode_params(param_hash)
          # TODO investigating whether a built-in method handles this
          # if no hash (e.g. no auth token) return empty string
          ((param_hash || {}).collect do |key_and_value| 
            key_and_value[1] = key_and_value[1].to_json if key_and_value[1].class != String
            "#{key_and_value[0].to_s}=#{CGI.escape key_and_value[1]}"
          end).join("&")
        end
      end
    end
  end

  module TyphoeusService
    # this service uses Typhoeus to send requests to the graph
    def self.included(base)
      base.class_eval do
        require 'typhoeus' unless defined?(Typhoeus)
        include Typhoeus

        def self.make_request(path, args, verb, options = {})
          # if the verb isn't get or post, send it as a post argument
          args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"
          server = options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER
          self.send(verb, "https://#{server}/#{path}", :params => args).body
        end
      end # class_eval
    end
  end
end