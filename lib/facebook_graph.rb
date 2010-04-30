require 'cgi'
require 'digest/md5'

# rubygems is required to support json, how facebook returns data
require 'rubygems'
require 'json'

# include default http services
require 'http_services'

module FacebookGraph
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

  FACEBOOK_GRAPH_SERVER = "graph.facebook.com"

  class API
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
    #    graph = Facebook::GraphAPI.new(access_token)
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
    # Facebook::get_user_from_cookie() method below to get the OAuth access token
    # for the active user from the cookie saved by the SDK.
            
    # initialize with an access token 
    def initialize(access_token = nil)
      @access_token = access_token
    end
    
    def get_object(id, args = {})
      # Fetchs the given object from the graph.
      request(id, args)
    end
    
    def get_objects(ids, args = {})
      # Fetchs all of the given object from the graph.
      # We return a map from ID to object. If any of the IDs are invalid,
      # we raise an exception.
      request("", args.merge("ids" => ids.join(",")))
    end
    
    def get_connections(id, connection_name, args = {})
      # Fetchs the connections for given object.
      request("#{id}/#{connection_name}", args)
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

      raise GraphAPIError.new(nil, "Write operations require an access token") unless @access_token
      request("#{parent_object}/#{connection_name}", args, "post")
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
      request(id, {}, "delete")
    end
    
    def search(search_terms, args = {})
      # Searches for a given term
      request("search", args.merge({:q => search_terms}))
    end
    
    def request(path, args = {}, verb = "get")
      # Fetches the given path in the Graph API.
      args["access_token"] = @access_token if @access_token
        
      # make the request via the provided service
      result = make_request(path, args, verb)
      
      # Facebook sometimes sends results like "true" and "false", which aren't strictly object
      # and cause JSON.parse to fail
      # so we account for that
      response = JSON.parse("[#{result}]")[0]

      # check for errors
      if response.is_a?(Hash) && error = response["error"]
        raise GraphAPIError.new(error["code"], error["message"])
      end
      
      response
    end
    
    # set up the http service used to make requests
    # you can use your own (for HTTParty, etc.) by calling FacebookGraph::API.http_service = YourModule
    def self.http_service=(service)
      self.send(:include, service)
    end
    
    # by default, try requiring Typhoeus -- if that works, use it
    begin
      require 'typhoeus'
      FacebookGraph::API.http_service = TyphoeusService
    rescue LoadError
      FacebookGraph::API.http_service = NetHTTPService
    end
  end
  
  class GraphAPIError < Exception
    attr_accessor :code
    def initialize(code, message)
      super(message)
      self.code = code  
    end
  end
  
  class OAuth    
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

      if fb_cookie = cookie_hash["fbs_" + app_id.to_s]
        # remove the opening/closing quote
        fb_cookie = fb_cookie.gsub(/\"/, "")

        # since we no longer get individual cookies, we have to separate out the components ourselves
        components = {}
        fb_cookie.split("&").map {|param| param = param.split("="); components[param[0]] = param[1]}

        auth_string = components.keys.sort.collect {|a| a == "sig" ? nil : "#{a}=#{components[a]}"}.reject {|a| a.nil?}.join("")
        sig = Digest::MD5.hexdigest(auth_string + app_secret)

        sig == components["sig"] && Time.now.to_i < components["expires"].to_i ? components : nil
      end
    end
    
    def oauth_code_url(callback = @oauth_code_url, permissions = nil)
      # Creates the URL for oauth authorization for a given callback and optional set of permissions
      scope = permissions ? "&scope=#{permissions.is_a?(Array) ? permissions.join(",") : permissions}" : ""
      "https://#{FACEBOOK_GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}#{scope}"    
    end
    
    def all_permissions
      USER_PERMISSIONS.concat(FRIEND_PERMISSIONS)
    end
    
    def oauth_token_url(code, callback = @oauth_token_url)
      # Creates the URL for the token corresponding to a given code generated by Facebook
      "https://#{FACEBOOK_GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{callback}&client_secret=#{@app_secret}&code=#{code}"
    end
    
    # for more details and up to date information, see http://developers.facebook.com/docs/authentication/permissions
    USER_PERMISSIONS = [
      # PUBLISHING
      "publish_stream", # Enables your application to post content, comments, and likes to a user's stream and to the streams of the user's friends, without prompting the user each time.
      "create_event", # Enables your application to create and modify events on the user's behalf
      "rsvp_event", # Enables your application to RSVP to events on the user's behalf
      "sms", # Enables your application to send messages to the user and respond to messages from the user via text message
      "offline_access", # Enables your application to perform authorized requests on behalf of the user at any time (e.g. permanent access token)
      
      # DATA ACCESS
      "email", # Provides access to the user's primary email address in the email  property
      "read_stream", # Provides access to all the posts in the user's News Feed and enables your application to perform searches against the user's News Feed
      "user_about_me", # Provides access to the "About Me" section of the profile in the about property
      "user_activities", # Provides access to the user's list of activities as the activities connection
      "user_birthday", # Provides access to the full birthday with year as the birthday_date property
      "user_education_history", # Provides access to education history as the education property
      "user_events", # Provides access to the list of events the user is attending as the events connection
      "user_groups", # Provides access to the list of groups the user is a member of as the groups connection
      "user_hometown", # Provides access to the user's hometown in the hometown property
      "user_interests", # Provides access to the user's list of interests as the interests connection
      "user_likes", # Provides access to the list of all of the pages the user has liked as the likes connection
      "user_location", # Provides access to the user's current location as the current_location property
      "user_notes", # Provides access to the user's notes as the notes connection
      "user_online_presence", # Provides access to the user's online/offline presence
      "user_photo_video_tags", # Provides access to the photos the user has been tagged in as the photos connection
      "user_photos", # Provides access to the photos the user has uploaded
      "user_relationships", # Provides access to the user's family and personal relationships and relationship status
      "user_religion_politics", # Provides access to the user's religious and political affiliations
      "user_status", # Provides access to the user's most recent status message
      "user_videos", # Provides access to the videos the user has uploaded
      "user_website", # Provides access to the user's web site URL
      "user_work_history", # Provides access to work history as the work property
      "read_friendlists", # Provides read access to the user's friend lists
      "read_requests" # Provides read access to the user's friend requests
    ]
    
    FRIEND_PERMISSIONS = [
      # DATA ACCESS
      "friends_about_me", # Provides access to the "About Me" section of the profile in the about property
      "friends_activities", # Provides access to the user's list of activities as the activities connection
      "friends_birthday", # Provides access to the full birthday with year as the birthday_date property
      "friends_education_history", # Provides access to education history as the education property
      "friends_events", # Provides access to the list of events the user is attending as the events connection
      "friends_groups", # Provides access to the list of groups the user is a member of as the groups connection
      "friends_hometown", # Provides access to the user's hometown in the hometown property
      "friends_interests", # Provides access to the user's list of interests as the interests connection
      "friends_likes", # Provides access to the list of all of the pages the user has liked as the likes connection
      "friends_location", # Provides access to the user's current location as the current_location property
      "friends_notes", # Provides access to the user's notes as the notes connection
      "friends_online_presence", # Provides access to the user's online/offline presence
      "friends_photo_video_tags", # Provides access to the photos the user has been tagged in as the photos connection
      "friends_photos", # Provides access to the photos the user has uploaded
      "friends_relationships", # Provides access to the user's family and personal relationships and relationship status
      "friends_religion_politics", # Provides access to the user's religious and political affiliations
      "friends_status", # Provides access to the user's most recent status message
      "friends_videos", # Provides access to the videos the user has uploaded
      "friends_website", # Provides access to the user's web site URL
      "friends_work_history" # Provides access to work history as the work property
    ]
  end
end