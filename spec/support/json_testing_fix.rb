# when testing across Ruby versions, we found that JSON string creation inconsistently ordered keys
# which is a problem because our mock testing service ultimately matches strings to see if requests are mocked
# this fix solves that problem by ensuring all hashes are created with a consistent key order every time
module MultiJson
  self.engine = :ok_json

  class << self
    def encode_with_ordering(object)
      # if it's a hash, recreate it with k/v pairs inserted in sorted-by-key order
      # (for some reason, REE fails if we don't assign the ternary result as a local variable
      # separately from calling encode_original)
      encode_original(sort_object(object))
    end

    alias_method :encode_original, :encode
    alias_method :encode, :encode_with_ordering
  
    def decode_with_ordering(string)
      sort_object(decode_original(string))
    end

    alias_method :decode_original, :decode
    alias_method :decode, :decode_with_ordering
    
    private 
  
    def sort_object(object)
      if object.is_a?(Hash)
        sort_hash(object)
      elsif object.is_a?(Array)
        object.collect {|item| item.is_a?(Hash) ? sort_hash(item) : item}
      else
        object
      end
    end
  
    def sort_hash(unsorted_hash)
      sorted_hash = KoalaTest::OrderedHash.new(sorted_hash)
      unsorted_hash.keys.sort {|a, b| a.to_s <=> b.to_s}.inject(sorted_hash) {|hash, k| hash[k] = unsorted_hash[k]; hash}
    end
  end
end
