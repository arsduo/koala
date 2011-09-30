require 'koala'

module Koala
  module Facebook
    module TestUserMethods

      def self.included(base)
        base.class_eval do
          # make the Graph API accessible in case someone wants to make other calls to interact with their users
          attr_reader :api, :app_id, :app_access_token, :secret
        end
      end

      def initialize(options = {})
        @app_id = options[:app_id]
        @app_access_token = options[:app_access_token]
        @secret = options[:secret]
        unless @app_id && (@app_access_token || @secret) # make sure we have what we need
          raise ArgumentError, "Initialize must receive a hash with :app_id and either :app_access_token or :secret! (received #{options.inspect})"
        end

        # fetch the access token if we're provided a secret
        if @secret && !@app_access_token
          oauth = Koala::Facebook::OAuth.new(@app_id, @secret)
          @app_access_token = oauth.get_app_access_token
        end
        @api = API.new(@app_access_token)
      end

      def create(installed, permissions = nil, args = {}, options = {})
        # Creates and returns a test user
        args['installed'] = installed
        args['permissions'] = (permissions.is_a?(Array) ? permissions.join(",") : permissions) if installed
        @api.graph_call(accounts_path, args, "post", options)
      end

      def list
        @api.graph_call(accounts_path)
      end

      def delete(test_user)
        test_user = test_user["id"] if test_user.is_a?(Hash)
        @api.delete_object(test_user)
      end

      def delete_all
        list.each {|u| delete u}
      end

      def update(test_user, args = {}, http_options = {})
        test_user = test_user["id"] if test_user.is_a?(Hash)
        @api.graph_call(test_user, args, "post", http_options)
      end

      def befriend(user1_hash, user2_hash)
        user1_id = user1_hash["id"] || user1_hash[:id]
        user2_id = user2_hash["id"] || user2_hash[:id]
        user1_token = user1_hash["access_token"] || user1_hash[:access_token]
        user2_token = user2_hash["access_token"] || user2_hash[:access_token]
        unless user1_id && user2_id && user1_token && user2_token
          # we explicitly raise an error here to minimize the risk of confusing output
          # if you pass in a string (as was previously supported) no local exception would be raised
          # but the Facebook call would fail
          raise ArgumentError, "TestUsers#befriend requires hash arguments for both users with id and access_token"
        end

        u1_graph_api = API.new(user1_token)
        u2_graph_api = API.new(user2_token)

        u1_graph_api.graph_call("#{user1_id}/friends/#{user2_id}", {}, "post") &&
          u2_graph_api.graph_call("#{user2_id}/friends/#{user1_id}", {}, "post")
      end

      def create_network(network_size, installed = true, permissions = '')
        users = (0...network_size).collect { create(installed, permissions) }
        friends = users.clone
        users.each do |user|
          # Remove this user from list of friends
          friends.delete_at(0)
          # befriend all the others
          friends.each do |friend|
            befriend(user, friend)
          end
        end
        return users
      end

      def graph_api
        Koala::Utils.deprecate("the TestUsers.graph_api accessor is deprecated and will be removed in a future version; please use .api instead.")
        @api
      end

      protected

      def accounts_path
        @accounts_path ||= "/#{@app_id}/accounts/test-users"
      end

    end # TestUserMethods
  end # Facebook
end # Koala
