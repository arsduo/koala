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

      def create_test_user(app_id, installed, permissions)
        # Creates and returns a test user
        args = {'installed' => installed}
        args['permissions'] = permissions if installed
        result = @graph_api.graph_call("#{app_id}/accounts/test_users", args, "post")
      end

    end # TestUserMethods
  end # Facebook
end # Koala
