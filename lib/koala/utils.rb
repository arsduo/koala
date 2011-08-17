module Koala
  module Utils
    def self.deprecate(message)
      begin
        send(:warn, "KOALA: Deprecation warning: #{message}")
      rescue Exception => err
        puts "Unable to issue Koala deprecation warning!  #{err.message}"
      end
    end
  end
end