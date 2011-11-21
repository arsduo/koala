module Koala
  module Utils

    # @private
    DEPRECATION_PREFIX = "KOALA: Deprecation warning: "

    # Prints a deprecation message.  
    # Each individual message will only be printed once to avoid spamming.
    def self.deprecate(message)
      @posted_deprecations ||= []
      unless @posted_deprecations.include?(message)
        # only include each message once
        Kernel.warn("#{DEPRECATION_PREFIX}#{message}")
        @posted_deprecations << message
      end
    end
  end
end