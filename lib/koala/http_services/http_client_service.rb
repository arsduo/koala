require "http_client" unless defined?(HTTP::Client)

module Koala
  module HttpClientService
    include Koala::HTTPService
    EntityUtils = org.apache.http.util.EntityUtils

    def self.make_request(path, args, verb, options = {})
      # you can pass arguments directly to HttpClient using the :client_options key
      client_options = {:params => args}.merge(options[:client_options] || {})

      # if proxy/timeout options aren't passed, check if defaults are set
      client_options[:default_proxy] ||= proxy
      client_options[:so_timeout]    ||= timeout

      client   = HTTP::Client.new(server(options), client_options)
      
      response = client.send(verb, "#{prefix}://#{server(options)}#{path}")
      status_code  = response.get_status_line.get_status_code
      headers_hash = Hash[ response.get_all_headers.map{|h| [h.get_name, h.get_value]} ]
      body         = EntityUtils.to_string response.get_entity
      Koala::Response.new(status_code, body, headers_hash)
    end
  
    protected
          
    def self.multipart_requires_content_type?
      false
    end
  end
end