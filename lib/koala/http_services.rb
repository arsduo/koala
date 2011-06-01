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