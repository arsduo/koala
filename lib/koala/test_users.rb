require 'koala'

module Koala
  module Facebook
    module TestUserMethods
      
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
        @graph_api = GraphAPI.new(@app_access_token)
      end

      def create(installed, permissions = nil)
        # Creates and returns a test user
        args = {'installed' => installed}
        args['permissions'] = (permissions.is_a?(Array) ? permissions.join(",") : permissions) if installed
        result = @graph_api.graph_call(accounts_path, args, "post")
      end
      
      def list
        @graph_api.graph_call(accounts_path)["data"]
      end
      
      def delete(test_user)
        test_user = test_user["id"] if test_user.is_a?(Hash)
        @graph_api.delete_object(test_user)
      end
      
      def delete_all
        list.each {|u| delete u }
      end
      
      def befriend(user1, user2)
        user1_id = user1["id"] if user1.is_a?(Hash)
        user2_id = user2["id"] if user2.is_a?(Hash)
        
        user1_token = user1["access_token"] if user1.is_a?(Hash)
        user2_token = user2["access_token"] if user2.is_a?(Hash)
        
        @u1_graph_api = GraphAPI.new(user1_token)
        @u2_graph_api = GraphAPI.new(user2_token)
        
        @u1_graph_api.graph_call(:path => "/#{user1_id}/friends/#{user2_id}")
        @u2_graph_api.graph_call(:path => "/#{user2_id}/friends/#{user1_id}")
        
        # This is the original Koala call, the one that doesn't work
        #@graph_api.graph_call(:path => "/#{user1}/friends/#{user2}") && @graph_api.graph_call(:path => "/#{user2}/friends/#{user1}")
      end
      
      def create_network(network_size, installed = true, permissions = '')
        network_size = 50 if network_size > 50 # FB's max is 50
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
      
      protected
      
      def accounts_path
        @accounts_path ||= "/#{@app_id}/accounts/test-users"
      end

    end # TestUserMethods
  end # Facebook
end # Koala
