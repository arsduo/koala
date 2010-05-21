module Koala
  module Facebook
    REST_SERVER = "api.facebook.com"
    
    module RestAPIMethods
      def fql_query(fql)
        rest_call('fql.query', 'query' => fql)
      end
      
      def rest_call(method, args = {})
        api("method/#{method}", args.merge('format' => 'json'), 'get', :rest_api => true)
      end
      
      def api(*args)
        response = super
        
        # check for REST API-specific errors
        if response.is_a?(Hash) && response["error_code"]
          raise APIError.new("type" => response["error_code"], "message" => response["error_msg"])
        end
        
        response
      end
    end
    
  end # module Facebook
end # module Koala