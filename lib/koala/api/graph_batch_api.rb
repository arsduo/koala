require "koala/api"
require "koala/api/batch_operation"

module Koala
  module Facebook
    # @private
    class GraphBatchAPI
      # inside a batch call we can do anything a regular Graph API can do
      include GraphAPIMethods

      # Limits from @see https://developers.facebook.com/docs/marketing-api/batch-requests/v2.8
      MAX_CALLS = 50

      attr_reader :original_api
      def initialize(api)
        @original_api = api
      end

      def batch_calls
        @batch_calls ||= []
      end

      # Enqueue a call into the batch for later processing.
      # See API#graph_call
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
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

      # execute the queued batch calls. limits it to 50 requests per call.
      # NOTE: if you use `name` and JsonPath references, you should ensure to call `execute` for each
      # co-reference group and that the group size is not greater than the above limits.
      def execute(http_options = {})
        return [] if batch_calls.empty?

        batch_results = []
        until batch_calls.empty? do
          batch = batch_calls.shift(MAX_CALLS)

          # Turn the call args collected into what facebook expects
          args = {"batch" => batch_args(batch)}
          batch.each do |call|
            args.merge!(call.files || {})
          end

          original_api.graph_call("/", args, "post", http_options) do |response|
            raise bad_response('Facebook returned an empty body') if response.nil?

            # when http_component is set we receive Koala::Http_service response object
            # from graph_call so this needs to be parsed
            # as generate_results method handles only JSON response
            if http_options[:http_component] && http_options[:http_component] == :response
              response = json_body(response.body)

              raise bad_response('Facebook returned an invalid body') unless response.is_a?(Array)
            end

            # FB sometimes truncates the submission batch. dhm thinks it may be limiting create actions
            # without erroring
            slice_results = generate_results(response, batch)
            batch_results += slice_results
            if slice_results.length < batch.length
              batch_calls.unshift(*batch[slice_results.length .. batch.length])
            end
          end
        end

        batch_results
      end

      def generate_results(response, batch)
        index = 0
        response.map do |call_result|
          batch_op = batch[index]
          index += 1
          post_process = batch_op.post_processing

          # turn any results that are pageable into GraphCollections
          result = result_from_response(call_result, batch_op)

          # and pass to post-processing callback if given
          if post_process
            post_process.call(result)
          else
            result
          end
        end
      end

      def bad_response(message)
        # Facebook sometimes reportedly returns an empty body at times
        BadFacebookResponse.new(200, '', message)
      end

      def result_from_response(response, options)
        return nil if response.nil?

        headers   = headers_from_response(response)
        error     = error_from_response(response, headers)
        component = options.http_options[:http_component]

        error || desired_component(
          component: component,
          response: response,
          headers: headers
        )
      end

      def headers_from_response(response)
        headers = response.fetch("headers", [])

        headers.inject({}) do |compiled_headers, header|
          compiled_headers.merge(header.fetch("name") => header.fetch("value"))
        end
      end

      def error_from_response(response, headers)
        code = response["code"]
        body = response["body"].to_s

        GraphErrorChecker.new(code, body, headers).error_if_appropriate
      end

      def batch_args(calls_for_batch)
        calls = calls_for_batch.map do |batch_op|
          batch_op.to_batch_params(access_token, app_secret)
        end

        JSON.dump calls
      end

      def json_body(body)
        return if body.nil?

        JSON.parse(body)
      rescue JSON::ParserError => e
        Koala::Utils.logger.error("#{e.class}: #{e.message} while parsing #{body}")
        nil
      end

      def desired_component(component:, response:, headers:)
        result = Koala::HTTPService::Response.new(response['code'], response['body'], headers)

        # Get the HTTP component they want
        case component
        when :status  then response["code"].to_i
        # facebook returns the headers as an array of k/v pairs, but we want a regular hash
        when :headers then headers
        # (see note in regular api method about JSON parsing)
        when :response then result
        else GraphCollection.evaluate(result, original_api)
        end
      end

      def access_token
        original_api.access_token
      end

      def app_secret
        original_api.app_secret
      end
    end
  end
end
