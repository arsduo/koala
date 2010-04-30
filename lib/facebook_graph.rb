require 'cgi'
require 'digest/md5'

# rubygems is required to support json, how facebook returns data
require 'rubygems'
require 'json'

# include default http services
require 'http_services'

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

  FACEBOOK_GRAPH_SERVER = "graph.facebook.com"

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
    # and a service that provides a make_request(path, args, verb) interface
    def initialize(access_token = nil, service_module = nil)
      @access_token = access_token
      
      unless service_module
        # try requiring Typhoeus -- if that works, use it
        begin
          require 'typhoeus'
          service_module = TyphoeusService
        rescue LoadError
          service_module = NetHTTPService
        end
      end
      self.class.send(:include, service_module)
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
  end
  
  class GraphAPIError < Exception
    attr_accessor :code
    def initialize(code, message)
      super(message)
      self.code = code  
    end
  end
  
  def self.get_user_from_cookie(cookies, app_id, app_secret)
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

    if fb_cookie = cookies["fbs_" + app_id.to_s]
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
end