module Koala
  module Facebook
    class BatchOperation
      attr_reader :access_token, :http_options, :post_processing, :files
       
      def initialize(options = {})
        @args = (options[:args] || {}).dup # because we modify it below
        @access_token = options[:access_token]
        @http_options = (options[:http_options] || {}).dup # dup because we modify it below
        @batch_args = @http_options.delete(:batch_args) || {}
        @url = options[:url]
        @method = options[:method].to_sym
        @post_processing = options[:post_processing]
        
        process_binary_args
        
        raise Koala::KoalaError, "Batch operations require an access token, none provided." unless @access_token
      end
      
      def to_batch_params(main_access_token)
        # set up the arguments
        args_string = Koala.http_service.encode_params(@access_token == main_access_token ? @args : @args.merge(:access_token => @access_token))
        
        response = {
          :method => @method, 
          :relative_url => @url,
        }
         
        # handle batch-level arguments, such as name, depends_on, and attached_files
        @batch_args[:attached_files] = @files.keys.join(",") if @files
        response.merge!(@batch_args) if @batch_args
        
        # for get and delete, we append args to the URL string
        # otherwise, they go in the body
        if args_string.length > 0
          if args_in_url?
            response[:relative_url] += (@url =~ /\?/ ? "&" : "?") + args_string if args_string.length > 0
          else
            response[:body] = args_string if args_string.length > 0
          end
        end
        
        response
      end
  
      protected
      
      def process_binary_args
        # collect binary files
        @args.each_pair do |key, value| 
          if UploadableIO.binary_content?(value)
            @files ||= {}
            # we use object_id to ensure unique file identifiers across multiple batch operations
            # remove it from the original hash and add it to the file store
            id = "file#{GraphAPI.batch_calls.length}_#{@files.keys.length}"
            @files[id] = @args.delete(key).is_a?(UploadableIO) ? value : UploadableIO.new(value)
          end
        end          
      end
      
      def args_in_url?
        @method == :get || @method == :delete 
      end   
    end
    
    module GraphAPIBatchMethods
      def self.included(base)
        base.class_eval do
          # batch mode flags
          def self.batch_mode?
            !!@batch_mode
          end

          def self.batch_calls
            raise KoalaError, "GraphAPI.batch_calls accessed when not in batch block!" unless batch_mode?
            @batch_calls
          end

          def self.batch(http_options = {}, &block)
            @batch_mode = true
            @batch_http_options = http_options
            @batch_calls = []
            yield
            begin
              results = batch_api(@batch_calls)
            ensure
              @batch_mode = false
            end
            results
          end

          def self.batch_api(batch_calls)
            return [] unless batch_calls.length > 0
            # Facebook requires a top-level access token

            # Get the access token for the user and start building a hash to store params
            # Turn the call args collected into what facebook expects
            args = {}
            access_token = args["access_token"] = batch_calls.first.access_token
            args['batch'] = batch_calls.map { |batch_op| 
              args.merge!(batch_op.files) if batch_op.files
              batch_op.to_batch_params(access_token)
            }.to_json
            
            # Make the POST request for the batch call
            # batch operations have to go over SSL, but since there's an access token, that secures that
            result = Koala.make_request('/', args, 'post', @batch_http_options) 
            # Raise an error if we get a 500
            raise APIError.new("type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}") if result.status >= 500

            response = JSON.parse(result.body.to_s)
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
                body = JSON.parse("[#{call_result['body'].to_s}]")[0]
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
  end
end