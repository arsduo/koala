require 'koala/api'
require 'koala/api/batch_operation'

module Koala
  module Facebook
    # @private
    class GraphBatchAPI < API
      # inside a batch call we can do anything a regular Graph API can do
      include GraphAPIMethods

      attr_reader :original_api
      def initialize(api)
        super(api.access_token, api.app_secret)
        @original_api = api
      end

      def batch_calls
        @batch_calls ||= []
      end

      def graph_call_in_batch(path, args = {}, verb = 'get', options = {}, &post_processing)
        # normalize options for consistency
        options = Koala::Utils.symbolize_hash(options)

        # for batch APIs, we queue up the call details (incl. post-processing)
        batch_calls << BatchOperation.new(
          :url => path,
          :args => args,
          :method => verb,
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

      # execute the queued batch calls
      def execute(http_options = {})
        return [] if batch_calls.empty?

        # Turn the call args collected into what facebook expects
        args = { 'batch' => batch_args }
        batch_calls.each do |call|
          args.merge! call.files || {}
        end

        graph_call_outside_batch('/', args, 'post', http_options, &handle_response)
      end

      def handle_response
        lambda do (response)
          raise bad_response if response.nil?
          response.map(&generate_results)
        end
      end

      def generate_results
        index = 0
        lambda do (call_result)
          batch_op     = batch_calls[index]; index += 1
          post_process = batch_op.post_processing

          # turn any results that are pageable into GraphCollections
          result = GraphCollection.evaluate(
            result_from_response(call_result, batch_op),
            original_api
          )

          # and pass to post-processing callback if given
          if post_process
            post_process.call(result)
          else
            result
          end
        end
      end

      def bad_response
        # Facebook sometimes reportedly returns an empty body at times
        BadFacebookResponse.new(200, '', 'Facebook returned an empty body')
      end

      def result_from_response(response, options)
        return nil if response.nil?

        headers   = coerced_headers_from_response(response)
        error     = error_from_response(response, headers)
        component = options.http_options[:http_component]

        error || result_from_component({
          :component => component,
          :response  => response,
          :headers   => headers
        })
      end

      def coerced_headers_from_response(response)
        headers = response.fetch('headers', [])

        headers.each_with_object({}) do |h, memo|
          memo.merge! h.fetch('name') => h.fetch('value')
        end
      end

      def error_from_response(response, headers)
        code = response['code']
        body = response['body'].to_s

        check_response(code, body, headers)
      end

      def batch_args
        calls = batch_calls.map do |batch_op|
          batch_op.to_batch_params(access_token, app_secret)
        end

        JSON.dump calls
      end

      def json_body(response)
        body = response.fetch('body')
        JSON.load("[#{body}]").first
      end

      def result_from_component(options)
        component = options.fetch(:component)
        response  = options.fetch(:response)
        headers   = options.fetch(:headers)

        # Get the HTTP component they want
        case component
        when :status  then response['code'].to_i
        # facebook returns the headers as an array of k/v pairs, but we want a regular hash
        when :headers then headers
        # (see note in regular api method about JSON parsing)
        else json_body(response)
        end
      end
    end
  end
end
