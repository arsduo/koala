require 'koala/api'
require 'koala/api/batch_operation'

module Koala
  module Facebook
    # @private
    class GraphBatchAPI < API
      # inside a batch call we can do anything a regular Graph API can do
      include GraphAPIMethods

      # Limits from @see https://developers.facebook.com/docs/marketing-api/batch-requests/v2.8
      MAX_AD_SUBMISSIONS = 10
      MAX_CALLS = 50
      AD_SUBMISSION_REGEX = Regexp.new('act_\d+/(ads|asyncadrequestsets)($|/)')

      attr_reader :original_api
      def initialize(api)
        super(api.access_token, api.app_secret)
        @original_api = api
      end

      def batch_calls
        @batch_calls ||= []
      end

      def graph_call_in_batch(path, args = {}, verb = "get", options = {}, &post_processing)
        # normalize options for consistency
        options = Koala::Utils.symbolize_hash(options)

        # for batch APIs, we queue up the call details (incl. post-processing)
        batch_calls << BatchOperation.new(
          :url => path,
          :args => args,
          :method => verb.downcase,
          :access_token => options[:access_token] || access_token,
          :http_options => options,
          :post_processing => post_processing
        )
        nil # batch operations return nothing immediately
      end

      # redefine the graph_call method so we can use this API inside the batch block
      # just like any regular Graph API
      alias_method :graph_call_outside_batch, :graph_call
      alias_method :graph_call, :graph_call_in_batch

      # execute the queued batch calls. limits it to 50 requests per call or 10 ad creations per call whichever
      # is less. NOTE: if you use `name` and JsonPath references, you should ensure to call `execute` for each
      # co-reference group and that the group size is not greater than the above limits.
      #
      def execute(http_options = {})
        return [] unless batch_calls.length > 0

        batch_calls.reverse!  # reverse so we can pop while preserving order
        batch_result = []
        until batch_calls.empty? do
          batch, batch_params = pop_batch(args = {})
          # Turn the call args collected into what facebook expects
          args["batch"] = JSON.dump(batch_params)

          graph_call_outside_batch('/', args, 'post', http_options) do |response|
            unless response
              # Facebook sometimes reportedly returns an empty body at times
              # see https://github.com/arsduo/koala/issues/184
              raise BadFacebookResponse.new(200, '', "Facebook returned an empty body")
            end

            # map the results with post-processing included
            index = 0 # keep compat with ruby 1.8 - no with_index for map
            response.map do |call_result|
              # Get the options hash
              batch_op = batch[index]
              index += 1

              raw_result = nil
              if call_result
                parsed_headers = if call_result.has_key?('headers')
                  call_result['headers'].inject({}) { |headers, h| headers[h['name']] = h['value']; headers}
                else
                  {}
                end

                if (error = check_response(call_result['code'], call_result['body'].to_s, parsed_headers))
                  raw_result = error
                else
                  # (see note in regular api method about JSON parsing)
                  body = JSON.load("[#{call_result['body'].to_s}]")[0]

                  # Get the HTTP component they want
                  raw_result = case batch_op.http_options[:http_component]
                  when :status
                    call_result["code"].to_i
                  when :headers
                    # facebook returns the headers as an array of k/v pairs, but we want a regular hash
                    parsed_headers
                  else
                    body
                  end
                end
              end

              # turn any results that are pageable into GraphCollections
              # and pass to post-processing callback if given
              result = GraphCollection.evaluate(raw_result, @original_api)
              if batch_op.post_processing
                batch_result << batch_op.post_processing.call(result)
              else
                batch_result << result
              end
            end
          end
        end
        batch_result
      end

      def pop_batch(args)
        batch_ad_count = 0
        batch = []
        batch_params = []
        MAX_CALLS.times do
          batch_op = batch_calls.pop
          return batch, batch_params if batch_op.nil?

          batch << batch_op

          batch_ad_count += 1 if batch_op.http_method == 'post' && batch_op.url =~ AD_SUBMISSION_REGEX

          args.merge!(batch_op.files) if batch_op.files
          batch_params << batch_op.to_batch_params(access_token, app_secret)

          return batch, batch_params if batch_ad_count >= MAX_AD_SUBMISSIONS
        end
        return batch, batch_params
      end
    end
  end
end
