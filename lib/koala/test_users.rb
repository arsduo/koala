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
      
      def befriend(user1_hash, user2_hash)
        user1_id = user1_hash["id"] || user1_hash[:id]
        user2_id = user2_hash["id"] || user2_hash[:id]
        user1_token = user1_hash["access_token"] || user1_hash[:access_token]
        user2_token = user2_hash["access_token"] || user2_hash[:access_token]
        unless user1_id && user2_id && user1_token && user2_token
          # we explicitly raise an error here to minimize the risk of confusing output
          # if you pass in a string (as was previously supported) no local exception would be raised
          # but the Facebook call would fail
          raise ArgumentError, "TestUsers#befriend requires hash arguments with id and access_token"
        end
        
        u1_graph_api = GraphAPI.new(user1_token)
        u2_graph_api = GraphAPI.new(user2_token)

        u1_graph_api.graph_call("#{user1_id}/friends/#{user2_id}", {}, "post") && 
          u2_graph_api.graph_call("#{user2_id}/friends/#{user1_id}", {}, "post")
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
