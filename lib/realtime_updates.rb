require 'koala'

module Koala
  module Facebook
    module RealtimeUpdateMethods
      # note: to subscribe to real-time updates, you must have an application access token
      
      def self.included(base)
        # make the attributes readable
        base.class_eval do
          attr_reader :app_id, :app_access_token, :secret
          
          # parses the challenge params and makes sure the call is legitimate
          # returns the challenge string to be sent back to facebook if true
          # returns false otherwise
          # this is a class method, since you don't need to know anything about the app
          # saves a potential trip fetching the app access token
          def self.meet_challenge(params, verify_token = nil, &verification_block)
            if params["hub.mode"] == "subscribe" &&
                # you can make sure this is legitimate through two ways
                # if your store the token across the calls, you can pass in the token value
                # and we'll make sure it matches
                (verify_token && params["hub.verify_token"] == verify_token) ||        
                # alternately, if you sent a specially-constructed value (such as a hash of various secret values)
                # you can pass in a block, which we'll call with the verify_token sent by Facebook
                # if it's legit, return anything that evaluates to true; otherwise, return nil or false
                (verification_block && yield(params["hub.verify_token"]))
              params["hub.challenge"]
            else
              false
            end
          end
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
          @app_access_token = oauth.get_app_access_token["access_token"]
        end
      end
      
      # subscribes for realtime updates
      # your callback_url must be set up to handle the verification request or the subscription will not be set up
      # http://developers.facebook.com/docs/api/realtime
      def subscribe(object, fields, callback_url, verify_token)
        args = {
          :object => object, 
          :fields => fields,
          :callback_url => callback_url,
          :verify_token => verify_token
        }
        api(subscription_path, args, 'post')
      end
            
      # removes subscription for object
      # if object is nil, it will remove all subscriptions
      def unsubscribe(object = nil)
        args = {}
        args[:object] = object if object
        api(subscription_path, args, 'delete')
      end
  
      def list_subscriptions
        api(subscription_path)
      end
      
      def api(*args) # same as GraphAPI
        response = super
        
        # check for errors
        if response.is_a?(Hash) && error_details = response["error"]
          raise APIError.new(error_details)
        end
      
        response
      end    
      
      protected
      
      def subscription_path
        @subscription_path ||= "#{@app_id}/subscriptions"
      end
    end
  end
end