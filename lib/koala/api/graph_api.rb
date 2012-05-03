require 'koala/api/graph_collection'
require 'koala/http_service/uploadable_io'

module Koala
  module Facebook
    GRAPH_SERVER = "graph.facebook.com"

    # Methods used to interact with the Facebook Graph API.
    #
    # See https://github.com/arsduo/koala/wiki/Graph-API for a general introduction to Koala
    # and the Graph API.
    #
    # The Graph API is made up of the objects in Facebook (e.g., people, pages,
    # events, photos, etc.) and the connections between them (e.g., friends,
    # photo tags, event RSVPs, etc.). Koala provides access to those
    # objects types in a generic way. For example, given an OAuth access
    # token, this will fetch the profile of the active user and the list
    # of the user's friends:
    #
    # @example
    #         graph = Koala::Facebook::API.new(access_token)
    #         user = graph.get_object("me")
    #         friends = graph.get_connections(user["id"], "friends")
    #
    # You can see a list of all of the objects and connections supported
    # by the API at http://developers.facebook.com/docs/reference/api/.
    #
    # You can obtain an access token via OAuth or by using the Facebook JavaScript SDK.
    # If you're using the JavaScript SDK, you can use the
    # {Koala::Facebook::OAuth#get_user_from_cookie} method to get the OAuth access token
    # for the active user from the cookie provided by Facebook.
    # See the Koala and Facebook documentation for more information.
    module GraphAPIMethods

      # Objects

      # Get information about a Facebook object.
      #
      # @param id the object ID (string or number)
      # @param args any additional arguments
      #         (fields, metadata, etc. -- see {http://developers.facebook.com/docs/reference/api/ Facebook's documentation})
      # @param options (see Koala::Facebook::API#api)
      #
      # @raise [Koala::Facebook::APIError] if the ID is invalid or you don't have access to that object
      #
      # @return a hash of object data
      def get_object(id, args = {}, options = {})
        # Fetchs the given object from the graph.
        graph_call(id, args, "get", options)
      end

      # Get information about multiple Facebook objects in one call.
      #
      # @param ids an array or comma-separated string of object IDs
      # @param args (see #get_object)
      # @param options (see Koala::Facebook::API#api)
      #
      # @raise [Koala::Facebook::APIError] if any ID is invalid or you don't have access to that object
      #
      # @return an array of object data hashes
      def get_objects(ids, args = {}, options = {})
        # Fetchs all of the given objects from the graph.
        # If any of the IDs are invalid, they'll raise an exception.
        return [] if ids.empty?
        graph_call("", args.merge("ids" => ids.respond_to?(:join) ? ids.join(",") : ids), "get", options)
      end

      # Write an object to the Graph for a specific user.
      # @see #put_connections
      #
      # @note put_object is (for historical reasons) the same as put_connections.
      #       Please use put_connections; in a future version of Koala (2.0?),
      #       put_object will issue a POST directly to an individual object, not to a connection.
      def put_object(parent_object, connection_name, args = {}, options = {})
        put_connections(parent_object, connection_name, args, options)
      end

      # Delete an object from the Graph if you have appropriate permissions.
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      #
      # @return true if successful, false (or an APIError) if not
      def delete_object(id, options = {})
        # Deletes the object with the given ID from the graph.
        raise AuthenticationError.new(nil, nil, "Delete requires an access token") unless @access_token
        graph_call(id, {}, "delete", options)
      end

      # Fetch information about a given connection (e.g. type of activity -- feed, events, photos, etc.)
      # for a specific user.
      # See {http://developers.facebook.com/docs/api Facebook's documentation} for a complete list of connections.
      #
      # @note to access connections like /user_id/CONNECTION/other_user_id,
      #       simply pass "CONNECTION/other_user_id" as the connection_name
      #
      # @param id (see #get_object)
      # @param connection_name what
      # @param args any additional arguments
      # @param options (see #get_object)
      #
      # @return [Koala::Facebook::API::GraphCollection] an array of object hashes (in most cases)
      def get_connection(id, connection_name, args = {}, options = {})
        # Fetchs the connections for given object.
        graph_call("#{id}/#{connection_name}", args, "get", options)
      end
      alias_method :get_connections, :get_connection


      # Write an object to the Graph for a specific user.
      # See {http://developers.facebook.com/docs/api#publishing Facebook's documentation}
      # for all the supported writeable objects.
      #
      # @note (see #get_connection)
      #
      # @example
      #         graph.put_connections("me", "feed", :message => "Hello, world")
      #         => writes "Hello, world" to the active user's wall
      #
      # Most write operations require extended permissions. For example,
      # publishing wall posts requires the "publish_stream" permission. See
      # http://developers.facebook.com/docs/authentication/ for details about
      # extended permissions.
      #
      # @param id (see #get_object)
      # @param connection_name (see #get_connection)
      # @param args (see #get_connection)
      # @param options (see #get_object)
      #
      # @return a hash containing the new object's id
      def put_connections(id, connection_name, args = {}, options = {})
        # Posts a certain connection
        raise AuthenticationError.new(nil, nil, "Write operations require an access token") unless @access_token
        graph_call("#{id}/#{connection_name}", args, "post", options)
      end

      # Delete an object's connection (for instance, unliking the object).
      #
      # @note (see #get_connection)
      #
      # @param id (see #get_object)
      # @param connection_name (see #get_connection)
      # @args (see #get_connection)
      # @param options (see #get_object)
      #
      # @return (see #delete_object)
      def delete_connections(id, connection_name, args = {}, options = {})
        # Deletes a given connection
        raise AuthenticationError.new(nil, nil, "Delete requires an access token") unless @access_token
        graph_call("#{id}/#{connection_name}", args, "delete", options)
      end

      # Fetches a photo.
      # (Facebook returns the src of the photo as a response header; this method parses that properly,
      # unlike using get_connections("photo").)
      #
      # @param options options for Facebook (see #get_object).
      #                        To get a different size photo, pass :type => size (small, normal, large, square).
      #
      # @note to delete photos or videos, use delete_object(id)
      #
      # @return the URL to the image
      def get_picture(object, args = {}, options = {})
        # Gets a picture object, returning the URL (which Facebook sends as a header)
        graph_call("#{object}/picture", args, "get", options.merge(:http_component => :headers)) do |result|
          result["Location"]
        end
      end

      # Upload a photo.
      #
      # This can be called in multiple ways:
      #   put_picture(file, [content_type], ...)
      #   put_picture(path_to_file, [content_type], ...)
      #   put_picture(picture_url, ...)
      #
      # You can also pass in uploaded files directly from Rails or Sinatra.
      # See {https://github.com/arsduo/koala/wiki/Uploading-Photos-and-Videos the Koala wiki} for more information.
      #
      # @param args (see #get_object)
      # @param target_id the Facebook object to which to post the picture (default: "me")
      # @param options (see #get_object)
      #
      # @example
      #     put_picture(file, content_type, {:message => "Message"}, 01234560)
      #     put_picture(params[:file], {:message => "Message"})
      #     # with URLs, there's no optional content type field
      #     put_picture(picture_url, {:message => "Message"}, my_page_id)
      #
      # @note to access the media after upload, you'll need the user_photos or user_videos permission as appropriate.
      #
      # @return (see #put_connections)
      def put_picture(*picture_args)
        put_connections(*parse_media_args(picture_args, "photos"))
      end

      # Upload a video.  Functions exactly the same as put_picture.
      # @see #put_picture
      def put_video(*video_args)
        args = parse_media_args(video_args, "videos")
        args.last[:video] = true
        put_connections(*args)
      end

      # Write directly to the user's wall.
      # Convenience method equivalent to put_connections(id, "feed").
      #
      # To get wall posts, use get_connections(user, "feed")
      # To delete a wall post, use delete_object(post_id)
      #
      # @param message the message to write for the wall
      # @param attachment a hash describing the wall post
      #         (see the {https://developers.facebook.com/docs/guides/attachments/ stream attachments} documentation.)
      # @param target_id the target wall
      # @param options (see #get_object)
      #
      # @example
      #       @api.put_wall_post("Hello there!", {
      #         "name" => "Link name"
      #         "link" => "http://www.example.com/",
      #         "caption" => "{*actor*} posted a new review",
      #         "description" => "This is a longer description of the attachment",
      #         "picture" => "http://www.example.com/thumbnail.jpg"
      #       })
      #
      # @see #put_connections
      # @return (see #put_connections)
      def put_wall_post(message, attachment = {}, target_id = "me", options = {})
        put_connections(target_id, "feed", attachment.merge({:message => message}), options)
      end

      # Comment on a given object.
      # Convenience method equivalent to put_connection(id, "comments").
      #
      # To delete comments, use delete_object(comment_id).
      # To get comments, use get_connections(object, "likes").
      #
      # @param id (see #get_object)
      # @param message the comment to write
      # @param options (see #get_object)
      #
      # @return (see #put_connections)
      def put_comment(id, message, options = {})
        # Writes the given comment on the given post.
        put_connections(id, "comments", {:message => message}, options)
      end

      # Like a given object.
      # Convenience method equivalent to put_connections(id, "likes").
      #
      # To get a list of a user's or object's likes, use get_connections(id, "likes").
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      #
      # @return (see #put_connections)
      def put_like(id, options = {})
        # Likes the given post.
        put_connections(id, "likes", {}, options)
      end

      # Unlike a given object.
      # Convenience method equivalent to delete_connection(id, "likes").
      #
      # @param id (see #get_object)
      # @param options (see #get_object)
      #
      # @return (see #delete_object)
      def delete_like(id, options = {})
        # Unlikes a given object for the logged-in user
        raise AuthenticationError.new(nil, nil, "Unliking requires an access token") unless @access_token
        graph_call("#{id}/likes", {}, "delete", options)
      end

      # Search for a given query among visible Facebook objects.
      # See {http://developers.facebook.com/docs/reference/api/#searching Facebook documentation} for more information.
      #
      # @param search_terms the query to search for
      # @param args additional arguments, such as type, fields, etc.
      # @param options (see #get_object)
      #
      # @return [Koala::Facebook::API::GraphCollection] an array of search results
      def search(search_terms, args = {}, options = {})
        args.merge!({:q => search_terms}) unless search_terms.nil?
        graph_call("search", args, "get", options)
      end

      # Convenience Methods
      # In general, we're trying to avoid adding convenience methods to Koala
      # except to support cases where the Facebook API requires non-standard input
      # such as JSON-encoding arguments, posts directly to objects, etc.

      # Make an FQL query.
      # Convenience method equivalent to get_object("fql", :q => query).
      #
      # @param query the FQL query to perform
      # @param args (see #get_object)
      # @param options (see #get_object)
      def fql_query(query, args = {}, options = {})
        get_object("fql", args.merge(:q => query), options)
      end

      # Make an FQL multiquery.
      # This method simplifies the result returned from multiquery into a more logical format.
      #
      # @param queries a hash of query names => FQL queries
      # @param args (see #get_object)
      # @param options (see #get_object)
      #
      # @example
      #     @api.fql_multiquery({
      #       "query1" => "select post_id from stream where source_id = me()",
      #       "query2" => "select fromid from comment where post_id in (select post_id from #query1)"
      #     })
      #     # returns {"query1" => [obj1, obj2, ...], "query2" => [obj3, ...]}
      #     # instead of [{"name":"query1", "fql_result_set":[]},{"name":"query2", "fql_result_set":[]}]
      #
      # @return a hash of FQL results keyed to the appropriate query
      def fql_multiquery(queries = {}, args = {}, options = {})
        if results = get_object("fql", args.merge(:q => MultiJson.dump(queries)), options)
          # simplify the multiquery result format
          results.inject({}) {|outcome, data| outcome[data["name"]] = data["fql_result_set"]; outcome}
        end
      end

      # Get a page's access token, allowing you to act as the page.
      # Convenience method for @api.get_object(page_id, :fields => "access_token").
      #
      # @param id the page ID
      # @param args (see #get_object)
      # @param options (see #get_object)
      #
      # @return the page's access token (discarding expiration and any other information)
      def get_page_access_token(id, args = {}, options = {})
        result = get_object(id, args.merge(:fields => "access_token"), options) do
          result ? result["access_token"] : nil
        end
      end

      # Fetchs the comments from fb:comments widgets for a given set of URLs (array or comma-separated string).
      # See https://developers.facebook.com/blog/post/490.
      #
      # @param urls the URLs for which you want comments
      # @param args (see #get_object)
      # @param options (see #get_object)
      #
      # @returns a hash of urls => comment arrays
      def get_comments_for_urls(urls = [], args = {}, options = {})
        return [] if urls.empty?
        args.merge!(:ids => urls.respond_to?(:join) ? urls.join(",") : urls)
        get_object("comments", args, options)
      end

      def set_app_restrictions(app_id, restrictions_hash, args = {}, options = {})
        graph_call(app_id, args.merge(:restrictions => MultiJson.dump(restrictions_hash)), "post", options)
      end

      # Certain calls such as {#get_connections} return an array of results which you can page through
      # forwards and backwards (to see more feed stories, search results, etc.).
      # Those methods use get_page to request another set of results from Facebook.
      #
      # @note You'll rarely need to use this method unless you're using Sinatra or another non-Rails framework
      #       (see {Koala::Facebook::GraphCollection GraphCollection} for more information).
      #
      # @param params an array of arguments to graph_call
      #               as returned by {Koala::Facebook::GraphCollection.parse_page_url}.
      #
      # @return Koala::Facebook::GraphCollection the appropriate page of results (an empty array if there are none)
      def get_page(params)
        graph_call(*params)
      end

      # Execute a set of Graph API calls as a batch.
      # See {https://github.com/arsduo/koala/wiki/Batch-requests batch request documentation}
      # for more information and examples.
      #
      # @param http_options HTTP options for the entire request.
      #
      # @yield batch_api [Koala::Facebook::GraphBatchAPI] an API subclass
      #                  whose requests will be queued and executed together at the end of the block
      #
      # @raise [Koala::Facebook::APIError] only if there is a problem with the overall batch request
      #                                    (e.g. connectivity failure, an operation with a missing dependency).
      #                                    Individual calls that error out will be represented as an unraised
      #                                    APIError in the appropriate spot in the results array.
      #
      # @example
      #         results = @api.batch do |batch_api|
      #          batch_api.get_object('me')
      #          batch_api.get_object(KoalaTest.user1)
      #         end
      #         # => [{"id" => my_id, ...}, {"id"" => koppel_id, ...}]
      #
      # @return an array of results from your batch calls (as if you'd made them individually),
      #         arranged in the same order they're made.
      def batch(http_options = {}, &block)
        batch_client = GraphBatchAPI.new(access_token, self)
        if block
          yield batch_client
          batch_client.execute(http_options)
        else
          batch_client
        end
      end

      # Make a call directly to the Graph API.
      # (See any of the other methods for example invocations.)
      #
      # @param path the Graph API path to query (no leading / needed)
      # @param args (see #get_object)
      # @param verb the type of HTTP request to make (get, post, delete, etc.)
      # @options (see #get_object)
      #
      # @yield response when making a batch API call, you can pass in a block
      #        that parses the results, allowing for cleaner code.
      #        The block's return value is returned in the batch results.
      #        See the code for {#get_picture} or {#fql_multiquery} for examples.
      #        (Not needed in regular calls; you'll probably rarely use this.)
      #
      # @raise [Koala::Facebook::APIError] if Facebook returns an error
      #
      # @return the result from Facebook
      def graph_call(path, args = {}, verb = "get", options = {}, &post_processing)
        result = api(path, args, verb, options) do |response|
          error = check_response(response.status, response.body)
          raise error if error
        end

        # turn this into a GraphCollection if it's pageable
        result = GraphCollection.evaluate(result, self)

        # now process as appropriate for the given call (get picture header, etc.)
        post_processing ? post_processing.call(result) : result
      end

      private

      def check_response(http_status, response_body)
        # Check for Graph API-specific errors. This returns an error of the appropriate type 
        # which is immediately raised (non-batch) or added to the list of batch results (batch)
        http_status = http_status.to_i

        if http_status >= 400
          begin
            response_hash = MultiJson.load(response_body)
          rescue MultiJson::DecodeError
            response_hash = {}
          end

          if response_hash['error_code']
            # Old batch api error format. This can be removed on July 5, 2012.
            # See https://developers.facebook.com/roadmap/#graph-batch-api-exception-format
            error_info = {
              'code' => response_hash['error_code'],
              'message' => response_hash['error_description']
            }
          else
            error_info = response_hash['error'] || {}
          end

          if error_info['type'] == 'OAuthException' && 
             ( !error_info['code'] || [102, 190, 450, 452, 2500].include?(error_info['code'].to_i))

            # See: https://developers.facebook.com/docs/authentication/access-token-expiration/
            #      https://developers.facebook.com/bugs/319643234746794?browse=search_4fa075c0bd9117b20604672
            AuthenticationError.new(http_status, response_body, error_info)
          else
            ClientError.new(http_status, response_body, error_info)
          end
        end
      end

      def parse_media_args(media_args, method)
        # photo and video uploads can accept different types of arguments (see above)
        # so here, we parse the arguments into a form directly usable in put_connections
        raise KoalaError.new("Wrong number of arguments for put_#{method == "photos" ? "picture" : "video"}") unless media_args.size.between?(1, 5)

        args_offset = media_args[1].kind_of?(Hash) || media_args.size == 1 ? 0 : 1

        args      = media_args[1 + args_offset] || {}
        target_id = media_args[2 + args_offset] || "me"
        options   = media_args[3 + args_offset] || {}

        if url?(media_args.first)
          # If media_args is a URL, we can upload without UploadableIO
          args.merge!(:url => media_args.first)
        else
          args["source"] = Koala::UploadableIO.new(*media_args.slice(0, 1 + args_offset))
        end

        [target_id, method, args, options]
      end

      def url?(data)
        return false unless data.is_a? String
        begin
          uri = URI.parse(data)
          %w( http https ).include?(uri.scheme)
        rescue URI::BadURIError
          false
        end
      end
    end
  end
end
