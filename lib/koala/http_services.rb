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
          attr_accessor :always_use_ssl, :proxy, :timeout
        end

        def self.server(options = {})
          "#{options[:beta] ? "beta." : ""}#{options[:rest_api] ? Facebook::REST_SERVER : Facebook::GRAPH_SERVER}"          
        end
        
        def self.encode_params(param_hash)
          # unfortunately, we can't use to_query because that's Rails, not Ruby
          # if no hash (e.g. no auth token) return empty string
          ((param_hash || {}).collect do |key_and_value|
            key_and_value[1] = key_and_value[1].to_json unless key_and_value[1].is_a? String
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
  end
end