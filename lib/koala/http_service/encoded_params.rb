module Koala
  module HTTPService
    class EncodedParams # :nodoc:
      def initialize(params)
        @params = (params || {}).sort_by{|k, _| k.to_s}
      end

      def to_s
        encode_from_params(stringify_values_from_params(@params))
      end

      private

      def stringify_values_from_params(params)
        params.collect do |(key, value)|
          unless value.is_a? String
            value = value.to_json
          end
          [key, value]
        end
      end

      def encode_from_params(params)
        params.collect do |(key, value)|
          "#{key}=#{CGI.escape value}"
        end.join("&")
      end
    end
  end
end
