module Koala
  module Utils

    DEPRECATION_PREFIX = "KOALA: Deprecation warning: "
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