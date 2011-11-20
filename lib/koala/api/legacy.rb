require 'koala/api'
module Koala
  module Facebook
    # Legacy support for old pre-1.2 APIs
    
    # A wrapper for the old APIs deprecated in 1.2.0, which triggers a deprecation warning when used.
    # Otherwise, this class functions identically to API.
    # @see API 
    # @private
    class OldAPI < API
      def initialize(*args)
        Koala::Utils.deprecate("#{self.class.name} is deprecated and will be removed in a future version; please use the API class instead.")
        super
      end
    end
    
    # @private
    class GraphAPI < OldAPI; end
    
    # @private
    class RestAPI < OldAPI; end
    
    # @private
    class GraphAndRestAPI < OldAPI; end
  end
end