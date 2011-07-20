module Koala
  module Facebook
    GRAPH_SERVER = "graph.facebook.com"   

    module GraphAPIMethods
      # A client for the Facebook Graph API.
      # 
      # See http://github.com/arsduo/koala for Ruby/Koala documentation
      # and http://developers.facebook.com/docs/api for Facebook API documentation
      # 
      # The Graph API is made up of the objects in Facebook (e.g., people, pages,
      # events, photos) and the connections between them (e.g., friends,
      # photo tags, and event RSVPs). This client provides access to those
      # primitive types in a generic way. For example, given an OAuth access
      # token, this will fetch the profile of the active user and the list
      # of the user's friends:
      # 
      #    graph = Koala::Facebook::GraphAPI.new(access_token)
      #    user = graph.get_object("me")
      #    friends = graph.get_connections(user["id"], "friends")
      # 
      # You can see a list of all of the objects and connections supported
      # by the API at http://developers.facebook.com/docs/reference/api/.
      # 
      # You can obtain an access token via OAuth or by using the Facebook
      # JavaScript SDK. See the Koala and Facebook documentation for more information.
      # 
      # If you are using the JavaScript SDK, you can use the
      # Koala::Facebook::OAuth.get_user_from_cookie() method below to get the OAuth access token
      # for the active user from the cookie saved by the SDK.

      # Objects

      def get_object(id, args = {}, options = {})
        # Fetchs the given object from the graph.
        graph_call(id, args, "get", options)
      end
    
      def get_objects(ids, args = {}, options = {})
        # Fetchs all of the given objects from the graph.
        # If any of the IDs are invalid, they'll raise an exception.
        return [] if ids.empty?
        graph_call("", args.merge("ids" => ids.respond_to?(:join) ? ids.join(",") : ids), "get", options)
      end
      
      def put_object(parent_object, connection_name, args = {}, options = {})
        # Writes the given object to the graph, connected to the given parent.
        # See http://developers.facebook.com/docs/api#publishing for all of
        # the supported writeable objects.
        # 
        # For example,
        #     graph.put_object("me", "feed", :message => "Hello, world")
        # writes "Hello, world" to the active user's wall.
        #
        # Most write operations require extended permissions. For example,
        # publishing wall posts requires the "publish_stream" permission. See
        # http://developers.facebook.com/docs/authentication/ for details about
        # extended permissions.
    
        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Write operations require an access token"}) unless @access_token
        graph_call("#{parent_object}/#{connection_name}", args, "post", options)
      end

      def delete_object(id, options = {})
        # Deletes the object with the given ID from the graph.
        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Delete requires an access token"}) unless @access_token
        graph_call(id, {}, "delete", options)
      end
      
      # Connections
          
      def get_connections(id, connection_name, args = {}, options = {})
        # Fetchs the connections for given object.
        graph_call("#{id}/#{connection_name}", args, "get", options) do |result|
          result ? GraphCollection.new(result, self) : nil # when facebook is down nil can be returned
        end
      end

      def get_comments_for_urls(urls = [], args = {}, options = {})
        # Fetchs the comments for given URLs (array or comma-separated string)
        # see https://developers.facebook.com/blog/post/490
        return [] if urls.empty?
        args.merge!(:ids => urls.respond_to?(:join) ? urls.join(",") : urls)
        get_object("comments", args, options)
      end
          
      def put_connections(id, connection_name, args = {}, options = {})
        # Posts a certain connection
        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Write operations require an access token"}) unless @access_token
        graph_call("#{id}/#{connection_name}", args, "post", options)
      end

      def delete_connections(id, connection_name, args = {}, options = {})
        # Deletes a given connection
        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Delete requires an access token"}) unless @access_token
        graph_call("#{id}/#{connection_name}", args, "delete", options)
      end

      # Media (photos and videos)
      # to delete photos or videos, use delete_object(object_id)
      # note: you'll need the user_photos or user_videos permissions to actually access media after upload 
    
      def get_picture(object, args = {}, options = {})
        # Gets a picture object, returning the URL (which Facebook sends as a header)
        graph_call("#{object}/picture", args, "get", options.merge(:http_component => :headers)) do |result|
          result["Location"]
        end
      end    
      
      # Can be called in multiple ways:
      #
      #   put_picture(file, [content_type], ...)
      #   put_picture(path_to_file, [content_type], ...)
      #
      # You can pass in uploaded files directly from Rails or Sinatra.
      # (See lib/koala/uploadable_io.rb for supported frameworks)
      #
      # Optional parameters can be added to the end of the argument list:
      # - args:       a hash of request parameters (default: {})
      # - target_id:  ID of the target where to post the picture (default: "me")
      # - options:    a hash of http options passed to the HTTPService module
      # 
      #   put_picture(file, content_type, {:message => "Message"}, 01234560)
      #   put_picture(params[:file], {:message => "Message"})
      
      def put_picture(*picture_args)
        put_object(*parse_media_args(picture_args, "photos"))
      end
        
      def put_video(*video_args)
        args = parse_media_args(video_args, "videos")
        args.last[:video] = true
        put_object(*args)
      end
    
      # Wall posts
      # To get wall posts, use get_connections(user, "feed")
      # To delete a wall post, just use delete_object(post_id)
    
      def put_wall_post(message, attachment = {}, profile_id = "me", options = {})
        # attachment is a hash describing the wall post
        # (see X for more details)
        # For instance, 
        # 
        #     {"name" => "Link name"
        #      "link" => "http://www.example.com/",
        #      "caption" => "{*actor*} posted a new review",
        #      "description" => "This is a longer description of the attachment",
        #      "picture" => "http://www.example.com/thumbnail.jpg"}

        self.put_object(profile_id, "feed", attachment.merge({:message => message}), options)
      end
      
      # Comments
      # to delete comments, use delete_object(comment_id)
      # to get comments, use get_connections(object, "likes")
      
      def put_comment(object_id, message, options = {})
        # Writes the given comment on the given post.
        self.put_object(object_id, "comments", {:message => message}, options)
      end
        
      # Likes
      # to get likes, use get_connections(user, "likes")
      
      def put_like(object_id, options = {})
        # Likes the given post.
        self.put_object(object_id, "likes", {}, options)
      end

      def delete_like(object_id, options = {})
        # Unlikes a given object for the logged-in user
        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Unliking requires an access token"}) unless @access_token
        graph_call("#{object_id}/likes", {}, "delete", options)
      end

      # Search
            
      def search(search_terms, args = {}, options = {})
        args.merge!({:q => search_terms}) unless search_terms.nil?
        graph_call("search", args, "get", options) do |result|
          result ? GraphCollection.new(result, self) : nil # when facebook is down nil can be returned
        end
      end      
      
      
      # GraphCollection support
      def get_page(params)
        # Pages through a set of results stored in a GraphCollection
        # Used for connections and search results
        graph_call(*params) do |result|
          result ? GraphCollection.new(result, self) : nil # when facebook is down nil can be returned
        end
      end
     
      # Page Access Token Support
      def get_page_access_token(object_id)
        result = get_object(object_id, :fields => "access_token")
        result ? result["access_token"] : nil
      end
      
      # Batch API
      def batch(http_options = {}, &block)
        batch_client = GraphBatchAPI.new(access_token)
        if block
          yield batch_client
          batch_client.execute(http_options)
        else
          batch_client
        end
      end        
      
      def self.included(base)
        base.class_eval do
          def self.batch
            raise NoMethodError, "The BatchAPI signature has changed (the original implementation was not thread-safe).  Please see https://github.com/arsduo/koala/wiki/Batch-requests.  (This message will be removed in the final 1.1 release.)"
          end
        end
      end
      
      # Direct access to the Facebook API
      # see any of the above methods for example invocations
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
        result = api(path, args, verb, options) do |response|
          error = check_response(response)
          raise error if error
        end

        # now process as appropriate (get picture header, make GraphCollection, etc.)
        post_processing ? post_processing.call(result) : result
      end
      
      def check_response(response)
        # check for Graph API-specific errors
        # this returns an error, which is immediately raised (non-batch)
        # or added to the list of batch results (batch)
        if response.is_a?(Hash) && error_details = response["error"]
          APIError.new(error_details) 
        end
      end
      
      private
      
      def parse_media_args(media_args, method)
        # photo and video uploads can accept different types of arguments (see above)
        # so here, we parse the arguments into a form directly usable in put_object
        raise KoalaError.new("Wrong number of arguments for put_#{method == "photos" ? "picture" : "video"}") unless media_args.size.between?(1, 5)
        
        args_offset = media_args[1].kind_of?(Hash) || media_args.size == 1 ? 0 : 1
        
        args      = media_args[1 + args_offset] || {}
        target_id = media_args[2 + args_offset] || "me"
        options   = media_args[3 + args_offset] || {} 
        
        args["source"] = Koala::UploadableIO.new(*media_args.slice(0, 1 + args_offset))

        options[:http_service] = Koala.base_http_service if args["source"].requires_base_http_service

        [target_id, method, args, options]
      end      
    end
  end
end  
