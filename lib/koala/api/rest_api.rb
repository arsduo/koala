module Koala
  module Facebook
    REST_SERVER = "api.facebook.com"

    # Methods used to interact with Facebook's legacy REST API.  
    # Where possible, you should use the newer, faster Graph API to interact with Facebook;
    # in the future, the REST API will be deprecated.
    # For now, though, there are a few methods that can't be done through the Graph API.
    #
    # When using the REST API, Koala will use Facebook's faster read-only servers 
    # whenever the call allows.  
    #
    # See https://github.com/arsduo/koala/wiki/REST-API for a general introduction to Koala
    # and the Rest API.
    module RestAPIMethods
      # Set a Facebook application's properties.
      # 
      # @param properties a hash of properties you want to update with their new values.
      # @param (see #rest_call)
      # @param options (see #rest_call)
      #
      # @return true if successful, false if not.  (This call currently doesn't give useful feedback on failure.)
      def set_app_properties(properties, args = {}, options = {})
        raise AuthenticationError.new(nil, nil, "setAppProperties requires an access token") unless @access_token
        rest_call("admin.setAppProperties", args.merge(:properties => MultiJson.dump(properties)), options, "post")
      end

      # Make a call to the REST API. 
      #
      # @note The order of the last two arguments is non-standard (for historical reasons).  Sorry.
      # 
      # @param fb_method the API call you want to make
      # @param args (see Koala::Facebook::GraphAPIMethods#graph_call)
      # @param options (see Koala::Facebook::GraphAPIMethods#graph_call)
      # @param verb (see Koala::Facebook::GraphAPIMethods#graph_call)
      # 
      # @raise [Koala::Facebook::APIError] if Facebook returns an error
      # 
      # @return the result from Facebook
      def rest_call(fb_method, args = {}, options = {}, verb = "get")
        Koala::Utils.deprecate("The REST API is now deprecated; please use the equivalent Graph API methods instead.  See http://developers.facebook.com/blog/post/616/.")

        options = options.merge!(:rest_api => true, :read_only => READ_ONLY_METHODS.include?(fb_method.to_s))

        api("method/#{fb_method}", args.merge('format' => 'json'), verb, options) do |response|
          # check for REST API-specific errors
          if response.status >= 400
            begin
              response_hash = MultiJson.load(response.body)
            rescue MultiJson::DecodeError
              response_hash = {}
            end

            error_info = {
              'code' => response_hash['error_code'],
              'error_subcode' => response_hash['error_subcode'],
              'message' => response_hash['error_msg']
            }

            if response.status >= 500
              raise ServerError.new(response.status, response.body, error_info)
            else
              raise ClientError.new(response.status, response.body, error_info)
            end
          end
        end
      end

      # @private
      # read-only methods for which we can use API-read
      # taken directly from the FB PHP library (https://github.com/facebook/php-sdk/blob/master/src/facebook.php)
      READ_ONLY_METHODS = [
        'admin.getallocation',
        'admin.getappproperties',
        'admin.getbannedusers',
        'admin.getlivestreamvialink',
        'admin.getmetrics',
        'admin.getrestrictioninfo',
        'application.getpublicinfo',
        'auth.getapppublickey',
        'auth.getsession',
        'auth.getsignedpublicsessiondata',
        'comments.get',
        'connect.getunconnectedfriendscount',
        'dashboard.getactivity',
        'dashboard.getcount',
        'dashboard.getglobalnews',
        'dashboard.getnews',
        'dashboard.multigetcount',
        'dashboard.multigetnews',
        'data.getcookies',
        'events.get',
        'events.getmembers',
        'fbml.getcustomtags',
        'feed.getappfriendstories',
        'feed.getregisteredtemplatebundlebyid',
        'feed.getregisteredtemplatebundles',
        'fql.multiquery',
        'fql.query',
        'friends.arefriends',
        'friends.get',
        'friends.getappusers',
        'friends.getlists',
        'friends.getmutualfriends',
        'gifts.get',
        'groups.get',
        'groups.getmembers',
        'intl.gettranslations',
        'links.get',
        'notes.get',
        'notifications.get',
        'pages.getinfo',
        'pages.isadmin',
        'pages.isappadded',
        'pages.isfan',
        'permissions.checkavailableapiaccess',
        'permissions.checkgrantedapiaccess',
        'photos.get',
        'photos.getalbums',
        'photos.gettags',
        'profile.getinfo',
        'profile.getinfooptions',
        'stream.get',
        'stream.getcomments',
        'stream.getfilters',
        'users.getinfo',
        'users.getloggedinuser',
        'users.getstandardinfo',
        'users.hasapppermission',
        'users.isappuser',
        'users.isverified',
        'video.getuploadlimits'
      ]
    end

  end # module Facebook
end # module Koala
