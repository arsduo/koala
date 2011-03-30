module Koala
  module Facebook
    module RawAPIMethods
      # This client works for undocumented (raw) data retrieval from Facebook
      # There doesn't currently seem to be much documentation on this subject
      # - Some commentary will be available in the source
      # - And I also intend to write a more thorough piece at some point
      require 'mechanize'

      FRIENDS_URL = 'http://www.facebook.com/ajax/browser/list/friends/all/?uid=[UID]&offset=[OFFSET]&dual=1&__a=1'

      # options
      # - :limit => limits the number of friends we get
      def get_friends(id, args = {}, options = {})
        friend_ids, index, body = [], 0, ''
        until body =~ /(Something went wrong\. We're working|Not Logged In)/ || (options[:limit] && friend_ids > options[:limit])
          page = @raw_session.agent.get(FRIENDS_URL.sub(/\[UID\]/, id).sub(/\[OFFSET\]/, (index * 120).to_s))
          friend_ids.concat(page.body.scan(/&quot;eng_tid&quot;:(\d+)/).flatten.uniq)
          index, body = index + 1, page.body
        end
        friend_ids = friend_ids.take(options[:limit]) if options[:limit]
        {:friend_ids => friend_ids}.to_json
      end

      def get_bio_data(id, args = {}, options = {})

      end
    end
  end
end
