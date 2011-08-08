module Koala
  module Utils
    def self.deprecate(message)
      send(:warn, "KOALA: Deprecation warning: #{message}")
    end
  end
end