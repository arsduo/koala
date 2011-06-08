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

      def self.included(base)
        base.class_eval do
          def self.check_response(response)
            # check for Graph API-specific errors
            # this returns an error, which is immediately raised (non-batch)
            # or added to the list of batch results (batch)
            if response.is_a?(Hash) && error_details = response["error"]
              APIError.new(error_details) 
            end
          end
        end
      end

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

      # Pictures
      # to delete pictures, use delete_object(photo_id)
      # note: you'll need the user_photos permission to actually access photos after uploading them 
    
      def get_picture(object, args = {}, options = {})
        # Gets a picture object, returning the URL (which Facebook sends as a header)
        graph_call("#{object}/picture", args, "get", options.merge(:http_component => :headers)) do |result|
          result["Location"]
        end
      end    
      
      def put_picture(*picture_args)
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
        
        raise KoalaError.new("Wrong number of arguments for put_picture") unless picture_args.size.between?(1, 5)
        
        args_offset = picture_args[1].kind_of?(Hash) || picture_args.size == 1 ? 0 : 1
        
        args      = picture_args[1 + args_offset] || {}
        target_id = picture_args[2 + args_offset] || "me"
        options   = picture_args[3 + args_offset] || {} 
        
        args["source"] = Koala::UploadableIO.new(*picture_args.slice(0, 1 + args_offset))

        options[:http_service] = Koala.base_http_service if args["source"].requires_base_http_service

        self.put_object(target_id, "photos", args, options)
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
      
      def batch(http_options = {}, &block)
        batch_client = GraphBatchAPI.new(access_token)
        yield batch_client
        batch_client.execute(http_options)
      end
        
    end
  end
end  
