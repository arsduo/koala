require 'cgi'
require 'digest/md5'

# rubygems is required to support json, how facebook returns data
require 'rubygems'
require 'json'

# include default http services
require 'http_services'

# REST API included at the bottom

module Koala
    
  module Facebook
    # Ruby client library for the Facebook Platform.
    # Copyright 2010 Facebook
    # Adapted from the Python library by Alex Koppel, Rafi Jacoby, and the team at Context Optional
    #
    # Licensed under the Apache License, Version 2.0 (the "License"); you may
    # not use this file except in compliance with the License. You may obtain
    # a copy of the License at
    #     http://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
    # WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
    # License for the specific language governing permissions and limitations
    # under the License.
    # 
    # This client library is designed to support the Graph API and the official
    # Facebook JavaScript SDK, which is the canonical way to implement
    # Facebook authentication. Read more about the Graph API at
    # http://developers.facebook.com/docs/api. You can download the Facebook
    # JavaScript SDK at http://github.com/facebook/connect-js/.

    GRAPH_SERVER = "graph.facebook.com"

    class GraphAPI
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
            
      # initialize with an access token 
      def initialize(access_token = nil)
        @access_token = access_token
      end
    
      def get_object(id, args = {})
        # Fetchs the given object from the graph.
        api(id, args)
      end
    
      def get_objects(ids, args = {})
        # Fetchs all of the given object from the graph.
        # We return a map from ID to object. If any of the IDs are invalid,
        # we raise an exception.
        api("", args.merge("ids" => ids.join(",")))
      end
    
      def get_connections(id, connection_name, args = {})
        # Fetchs the connections for given object.
        api("#{id}/#{connection_name}", args)
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
        api("#{parent_object}/#{connection_name}", args, "post")
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
        api(id, {}, "delete")
      end
    
      def search(search_terms, args = {})
        # Searches for a given term
        api("search", args.merge({:q => search_terms}))
      end
    
      def api(path, args = {}, verb = "get", options = {})
        # Fetches the given path in the Graph API.
        args["access_token"] = @access_token if @access_token
        
        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)
      
        # Facebook sometimes sends results like "true" and "false", which aren't strictly object
        # and cause JSON.parse to fail
        # so we account for that
        response = JSON.parse("[#{result}]")[0]

        # check for errors
        if response.is_a?(Hash) && error_details = response["error"]
          raise APIError.new(error_details)
        end
      
        response
      end
    end
  
    class APIError < Exception
      attr_accessor :fb_error_type
      def initialize(details = {})
        self.fb_error_type = details["type"]  
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
  
    class OAuth
      attr_accessor :app_id, :app_secret, :oauth_callback_url
      def initialize(app_id, app_secret, oauth_callback_url = nil)
        @app_id = app_id
        @app_secret = app_secret
        @oauth_callback_url = oauth_callback_url 
      end
    
      def get_user_from_cookie(cookie_hash)
        # Parses the cookie set by the official Facebook JavaScript SDK.
        # 
        # cookies should be a dictionary-like object mapping cookie names to
        # cookie values.
        # 
        # If the user is logged in via Facebook, we return a dictionary with the
        # keys "uid" and "access_token". The former is the user's Facebook ID,
        # and the latter can be used to make authenticated requests to the Graph API.
        # If the user is not logged in, we return None.
        # 
        # Download the official Facebook JavaScript SDK at
        # http://github.com/facebook/connect-js/. Read more about Facebook
        # authentication at http://developers.facebook.com/docs/authentication/.

        if fb_cookie = cookie_hash["fbs_" + @app_id.to_s]
          # remove the opening/closing quote
          fb_cookie = fb_cookie.gsub(/\"/, "")

          # since we no longer get individual cookies, we have to separate out the components ourselves
          components = {}
          fb_cookie.split("&").map {|param| param = param.split("="); components[param[0]] = param[1]}

          # generate the signature and make sure it matches what we expect
          auth_string = components.keys.sort.collect {|a| a == "sig" ? nil : "#{a}=#{components[a]}"}.reject {|a| a.nil?}.join("")
          sig = Digest::MD5.hexdigest(auth_string + @app_secret)          
          sig == components["sig"] && (components["expires"] == "0" || Time.now.to_i < components["expires"].to_i) ? components : nil
        end
      end
      alias_method :get_user_from_cookies, :get_user_from_cookie
    
      def url_for_oauth_code(options = {})
        # for permissions, see http://developers.facebook.com/docs/authentication/permissions
        permissions = options[:permissions]
        scope = permissions ? "&scope=#{permissions.is_a?(Array) ? permissions.join(",") : permissions}" : ""

        callback = options[:callback] || @oauth_callback_url
        raise ArgumentError, "url_for_oauth_code must get a callback either from the OAuth object or in the options!" unless callback

        # Creates the URL for oauth authorization for a given callback and optional set of permissions
        "https://#{GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}#{scope}"    
      end
        
      def url_for_access_token(code, options = {})
        # Creates the URL for the token corresponding to a given code generated by Facebook
        if options.is_a?(String) # changing the arguments
          puts "Deprecation warning: url_for_access_token now takes an options hash as the second argument; pass the callback as :callback."
          options = {:callback => options}
        end
        callback = options[:callback] || @oauth_callback_url
        raise ArgumentError, "url_for_access_token must get a callback either from the OAuth object or in the parameters!" unless callback
        "https://#{GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{callback}&client_secret=#{@app_secret}&code=#{code}"
      end
      
      def parse_access_token(response_text)
        components = response_text.split("&").inject({}) do |hash, bit|
          key, value = bit.split("=")
          hash.merge!(key => value)
        end
        components 
      end

      def fetch_token_string(code)
        Koala.make_request("oauth/access_token", {
          :client_id => @app_id, 
          :redirect_uri => @oauth_callback_url, 
          :client_secret => @app_secret, 
          :code => code
        }, "get")
      end
      
      def get_access_token(code)
        result = fetch_token_string(code)
        
        # if we have an error, parse the error JSON and raise an error
        raise GraphAPIError.new((JSON.parse(result)["error"] rescue nil) || {}) if result =~ /error/
        # otherwise, parse the access token
        parse_access_token(result)
      end
    end
  end
  
  # finally, set up the http service Koala methods used to make requests
  # you can use your own (for HTTParty, etc.) by calling Koala.http_service = YourModule
  def self.http_service=(service)
    self.send(:include, service)
  end

  # by default, try requiring Typhoeus -- if that works, use it
  begin
    require 'typhoeus'
    Koala.http_service = TyphoeusService
  rescue LoadError
    Koala.http_service = NetHTTPService
  end
end

# add the REST API class
require 'rest_api'
