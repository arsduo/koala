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
    
    def self.server(options = {})
      server = "#{options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER}"
      server.gsub!(/\.facebook/, "-video.facebook") if options[:video]
      "https://#{options[:beta] ? "beta." : ""}#{server}"
    end

    def self.make_request(path, args, verb, options = {})
      # We translate args to a valid query string. If post is specified,
      # we send a POST request to the given path with the given arguments.
      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"
      options = {:url => "#{server(options)}#{path}", :params => args}.merge(Koala.http_options || {}).merge(options)
      
      conn = Faraday.new(options) do |builder|
        builder.request :url_encoded  # convert request params as "www-form-urlencoded"
        builder.request :multipart if params_require_multipart?(args)
        builder.adapter Faraday.default_adapter
      end

      response = conn.send(verb)
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
    
    protected

    def self.params_require_multipart?(param_hash)
      param_hash.any? { |key, value| value.kind_of?(Koala::UploadableIO) }
    end

    def self.multipart_requires_content_type?
      true
    end
  end
end