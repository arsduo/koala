module Koala
  module Facebook
    module GraphSingleInvoker
      # Make a call which may or may not be batched
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
        # Direct access to the Facebook API
        # see any of the above methods for example invocations
        result = api(path, args, verb, options) do |response|
          if error = GraphAPI.check_response(response)
            raise error
          end
        end
        
        # now process as appropriate (get picture header, make GraphCollection, etc.)
        post_processing ? post_processing.call(result) : result
      end
      
    end
  end
end
