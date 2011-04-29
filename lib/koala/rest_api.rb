module Koala
  module Facebook
    REST_SERVER = "api.facebook.com"

    module RestAPIMethods
      def fql_query(fql)
        rest_call('fql.query', 'query' => fql)
      end

      def rest_call(method, args = {}, options = {})
        options = options.merge!(:rest_api => true, :read_only => READ_ONLY_METHODS.include?(method))

        response = api("method/#{method}", args.merge('format' => 'json'), 'get', options) do |response|
          # check for REST API-specific errors
          if response.is_a?(Hash) && response["error_code"]
            raise APIError.new("type" => response["error_code"], "message" => response["error_msg"])
          end
        end

        response
      end


      def post_rest_call(method, args = {}, options = {})
        options = options.merge!(:rest_api => true, :read_only => READ_ONLY_METHODS.include?(method))

        response = api("method/#{method}", args.merge('format' => 'json'), 'post', options) do |response|
          # check for REST API-specific errors
          if response.is_a?(Hash) && response["error_code"]
            raise APIError.new("type" => response["error_code"], "message" => response["error_msg"])
          end
        end

        response
      end

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
