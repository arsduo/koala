module Koala
  module Facebook
    GRAPH_SERVER = "graph.facebook.com"

    module GraphAPIMethods
      # A client for the Facebook Graph API.
      # 
      # See http://developers.facebook.com/docs/api for complete documentation
      # for the API.
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
      # JavaScript SDK. See http://developers.facebook.com/docs/authentication/
      # for details.
      # 
      # If you are using the JavaScript SDK, you can use the
      # Koala::Facebook::OAuth.get_user_from_cookie() method below to get the OAuth access token
      # for the active user from the cookie saved by the SDK.
            
      def get_object(id, args = {})
        # Fetchs the given object from the graph.
        graph_call(id, args)
      end
    
      def get_objects(ids, args = {})
        # Fetchs all of the given object from the graph.
        # We return a map from ID to object. If any of the IDs are invalid,
        # we raise an exception.
        graph_call("", args.merge("ids" => ids.join(",")))
      end
    
      def get_connections(id, connection_name, args = {})
        # Fetchs the connections for given object.
        graph_call("#{id}/#{connection_name}", args)
      end
    
      def get_picture(object)
        result = graph_call("#{object}/picture", {}, "get", :http_component => :headers)
        result["Location"]
      end
    
      def put_object(parent_object, connection_name, args = {})
        # Writes the given object to the graph, connected to the given parent.
        # 
        # For example,
        # 
        #     graph.put_object("me", "feed", :message => "Hello, world")
        # 
        # writes "Hello, world" to the active user's wall. Likewise, this
        # will comment on a the first post of the active user's feed:
        # 
        #     feed = graph.get_connections("me", "feed")
        #     post = feed["data"][0]
        #     graph.put_object(post["id"], "comments", :message => "First!")
        # 
        # See http://developers.facebook.com/docs/api#publishing for all of
        # the supported writeable objects.
        # 
        # Most write operations require extended permissions. For example,
        # publishing wall posts requires the "publish_stream" permission. See
        # http://developers.facebook.com/docs/authentication/ for details about
        # extended permissions.

        raise APIError.new({"type" => "KoalaMissingAccessToken", "message" => "Write operations require an access token"}) unless @access_token
        graph_call("#{parent_object}/#{connection_name}", args, "post")
      end
    
      def put_wall_post(message, attachment = {}, profile_id = "me")
        # Writes a wall post to the given profile's wall.
        # 
        # We default to writing to the authenticated user's wall if no
        # profile_id is specified.
        # 
        # attachment adds a structured attachment to the status message being
        # posted to the Wall. It should be a dictionary of the form:
        # 
        #     {"name": "Link name"
        #      "link": "http://www.example.com/",
        #      "caption": "{*actor*} posted a new review",
        #      "description": "This is a longer description of the attachment",
        #      "picture": "http://www.example.com/thumbnail.jpg"}

        self.put_object(profile_id, "feed", attachment.merge({:message => message}))
      end
    
      def put_comment(object_id, message)
        # Writes the given comment on the given post.
        self.put_object(object_id, "comments", {:message => message})
      end
    
      def put_like(object_id)
        # Likes the given post.
        self.put_object(object_id, "likes")
      end
    
      def delete_object(id)
        # Deletes the object with the given ID from the graph.
        graph_call(id, {}, "delete")
      end
    
      def search(search_terms, args = {})
        # Searches for a given term
        graph_call("search", args.merge({:q => search_terms}))
      end
    
      def graph_call(*args)
        response = api(*args) do |response|
          # check for Graph API-specific errors
          if response.is_a?(Hash) && error_details = response["error"]
            raise APIError.new(error_details)
          end
        end
      
        response
      end
    end
  end
end