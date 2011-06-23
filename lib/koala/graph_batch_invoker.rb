module Koala
  module Facebook
      module GraphBatchInvoker
        
      # API access

      # Make a call which may or may not be batched
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
          # for batch APIs, we queue up the call details (incl. post-processing)
          batch_calls << BatchOperation.new(
            {:url => path,
            :args => args,
            :method => verb,
            :access_token => options['access_token'] || access_token,
            :http_options => options,
            :post_processing => post_processing}
          )
          nil # batch operations return nothing immediately 
      end

      def batch_calls
        @batch_calls ||= []
      end

      def execute(http_options = {})
        return [] unless batch_calls.length > 0
        # Facebook requires a top-level access token

        # Get the access token for the user and start building a hash to store params
        # Turn the call args collected into what facebook expects
        args = {"access_token" => access_token}

        args["batch"] = MultiJson.encode(batch_calls.map { |batch_op|
            args.merge!(batch_op.files) if batch_op.files
            batch_op.to_batch_params(access_token)
          })
        
        # Make the POST request for the batch call
        # batch operations have to go over SSL, but since there's an access token, that secures that
        result = Koala.make_request('/', args, 'post', http_options) 
        # Raise an error if we get a 500
        raise APIError.new("type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}") if result.status >= 500

        response = MultiJson.decode(result.body.to_s)
        # raise an error if we get a Batch API error message
        raise APIError.new("type" => "Error #{response["error"]}", "message" => response["error_description"]) if response.is_a?(Hash) && response["error"]

        # otherwise, map the results with post-processing included            
        index = 0 # keep compat with ruby 1.8 - no with_index for map
        response.map do |call_result|
          # Get the options hash
          batch_op = batch_calls[index]
          index += 1

          if call_result
            # (see note in regular api method about JSON parsing)
            body = MultiJson.decode("[#{call_result['body'].to_s}]")[0]
            unless call_result["code"].to_i >= 500 || error = GraphAPI.check_response(body)
              # Get the HTTP component they want
              data = case batch_op.http_options[:http_component] 
              when :status
                call_result["code"].to_i
              when :headers
                # facebook returns the headers as an array of k/v pairs, but we want a regular hash
                call_result['headers'].inject({}) { |headers, h| headers[h['name']] = h['value']; headers}
              else
                body
              end
            
              # process it if we are given a block to process with
              batch_op.post_processing ? batch_op.post_processing.call(data) : data
            else
              error || APIError.new({"type" => "HTTP #{call_result["code"].to_s}", "message" => "Response body: #{body}"})
            end
          else
            nil
          end
        end
      end
      
    end
  end
end
