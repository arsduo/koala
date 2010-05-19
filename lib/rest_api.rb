module Koala
  module Facebook
    REST_SERVER = "api.facebook.com"
    
    module RestAPIMethods
      def fql_query(fql)
        api("method/fql.query", { "query" => fql }, "get")
      end
      
      def api(path, args = {}, verb = "get", options = {})
        response = super(path, args.merge("format" => "json"), verb, options.merge(:rest_api => true))
        
        # check for REST API-specific errors
        if response.is_a?(Hash) && response["error_code"]
          raise APIError.new("type" => response["error_code"], "message" => response["error_msg"])
        end
        
        response
      end
    end
    
  end # module Facebook
end # module Koala