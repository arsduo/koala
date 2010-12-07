require 'cgi'
require 'digest/md5'

# rubygems is required to support json, how facebook returns data
require 'rubygems'
require 'json'

# openssl is required to support signed_request
require 'openssl'

# include default http services
require 'koala/http_services'

# add Graph API methods
require 'koala/graph_api'

# add REST API methods
require 'koala/rest_api'

require 'koala/realtime_updates'

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

    class API
      # initialize with an access token 
      def initialize(access_token = nil)
        @access_token = access_token
      end
      
      def api(path, args = {}, verb = "get", options = {}, &error_checking_block)
        # Fetches the given path in the Graph API.
        args["access_token"] = @access_token || @app_access_token if @access_token || @app_access_token

        # add a leading /
        path = "/#{path}" unless path =~ /^\//

        # make the request via the provided service
        result = Koala.make_request(path, args, verb, options)
        
        # Check for any 500 errors before parsing the body
        # since we're not guaranteed that the body is valid JSON
        # in the case of a server error
        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status >= 500
        
        # Parse the body as JSON and check for errors if provided a mechanism to do so 
        # Note: Facebook sometimes sends results like "true" and "false", which aren't strictly objects
        # and cause JSON.parse to fail -- so we account for that by wrapping the result in []
        body = response = JSON.parse("[#{result.body.to_s}]")[0]
        if error_checking_block
          yield(body)
        end
        
        # now return the desired information
        if options[:http_component]
          result.send(options[:http_component])
        else
          body
        end
      end
    end
    
    class GraphAPI < API
      include GraphAPIMethods
    end
    
    class RestAPI < API
      include RestAPIMethods
    end
    
    class GraphAndRestAPI < API
      include GraphAPIMethods
      include RestAPIMethods
    end
    
    class RealtimeUpdates < API
      include RealtimeUpdateMethods
    end
    
    class APIError < Exception
      attr_accessor :fb_error_type
      def initialize(details = {})
        self.fb_error_type = details["type"]  
        super("#{fb_error_type}: #{details["message"]}")
      end
    end
    
    
    class OAuth
      attr_reader :app_id, :app_secret, :oauth_callback_url
      def initialize(app_id, app_secret, oauth_callback_url = nil)
        @app_id = app_id
        @app_secret = app_secret
        @oauth_callback_url = oauth_callback_url 
      end

      def get_user_info_from_cookie(cookie_hash)
        # Parses the cookie set by the official Facebook JavaScript SDK.
        # 
        # cookies should be a Hash, like the one Rails provides
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
      alias_method :get_user_info_from_cookies, :get_user_info_from_cookie
    
      def get_user_from_cookie(cookies)
        if info = get_user_info_from_cookies(cookies)
          string = info["uid"]
        end
      end
      alias_method :get_user_from_cookies, :get_user_from_cookie
    
      # URLs
    
      def url_for_oauth_code(options = {})
        # for permissions, see http://developers.facebook.com/docs/authentication/permissions
        permissions = options[:permissions]
        display = options.has_key?(:display) ? options[:display] : "page"
        scope = permissions ? "&scope=#{permissions.is_a?(Array) ? permissions.join(",") : permissions}" : ""
        
        callback = options[:callback] || @oauth_callback_url
        raise ArgumentError, "url_for_oauth_code must get a callback either from the OAuth object or in the options!" unless callback

        # Creates the URL for oauth authorization for a given callback and optional set of permissions
        "https://#{GRAPH_SERVER}/oauth/authorize?client_id=#{@app_id}&redirect_uri=#{callback}#{scope}&display=#{display}"    
      end
        
      def url_for_access_token(code, options = {})
        # Creates the URL for the token corresponding to a given code generated by Facebook
        callback = options[:callback] || @oauth_callback_url
        raise ArgumentError, "url_for_access_token must get a callback either from the OAuth object or in the parameters!" unless callback
        "https://#{GRAPH_SERVER}/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{callback}&client_secret=#{@app_secret}&code=#{code}"
      end
            
      def get_access_token_info(code)
        # convenience method to get a parsed token from Facebook for a given code
        # should this require an OAuth callback URL?
        get_token_from_server(:code => code, :redirect_uri => @oauth_callback_url)
      end
      
      def get_access_token(code)
        # upstream methods will throw errors if needed
        if info = get_access_token_info(code) 
          string = info["access_token"]        
        end
      end
      
      def get_app_access_token_info
        # convenience method to get a the application's sessionless access token 
        get_token_from_server({:type => 'client_cred'}, true)
      end
      
      def get_app_access_token
        if info = get_app_access_token_info
          string = info["access_token"] 
        end
      end
      
      # signed_request
      def parse_signed_request(request)
        # Facebook's signed requests come in two parts -- the signature and the data payload
        # see http://developers.facebook.com/docs/authentication/canvas
        encoded_sig, payload = request.split(".")
        
        sig = base64_url_decode(encoded_sig)

        # if the signature matches, return the data, decoded and parsed as JSON
        if OpenSSL::HMAC.digest("sha256", @app_secret, payload) == sig
          JSON.parse(base64_url_decode(payload))
        else
          nil
        end
      end

      # from session keys
      def get_token_info_from_session_keys(sessions)
        # fetch the OAuth tokens from Facebook
        response = fetch_token_string({
          :type => 'client_cred',
          :sessions => sessions.join(",")
        }, true, "exchange_sessions")
        
        # Facebook returns an empty body in certain error conditions
        if response == "" 
          raise APIError.new({
            "type" => "ArgumentError", 
            "message" => "get_token_from_session_key received an error (empty response body) for sessions #{sessions.inspect}!"
          })
        end
        
        JSON.parse(response)
      end
  
      def get_tokens_from_session_keys(sessions)
        # get the original hash results
        results = get_token_info_from_session_keys(sessions)
        # now recollect them as just the access tokens
        results.collect { |r| r ? r["access_token"] : nil }
      end
      
      def get_token_from_session_key(session)
        # convenience method for a single key
        # gets the overlaoded strings automatically
        get_tokens_from_session_keys([session])[0]
      end
      
      protected
      
      def get_token_from_server(args, post = false)
        # fetch the result from Facebook's servers
        result = fetch_token_string(args, post)
        
        # if we have an error, parse the error JSON and raise an error
        raise APIError.new((JSON.parse(result)["error"] rescue nil) || {}) if result =~ /error/

        # otherwise, parse the access token
        parse_access_token(result)       
      end
      
      def parse_access_token(response_text)
        components = response_text.split("&").inject({}) do |hash, bit|
          key, value = bit.split("=")
          hash.merge!(key => value)
        end
        components 
      end

      def fetch_token_string(args, post = false, endpoint = "access_token")
        Koala.make_request("/oauth/#{endpoint}", {
          :client_id => @app_id, 
          :client_secret => @app_secret
        }.merge!(args), post ? "post" : "get").body
      end
      
      # base 64
      def base64_url_decode(string)
        # to properly decode what Facebook provides, we need to add == to the end
        # and translate certain characters to others before running the actual decoding
        # see http://developers.facebook.com/docs/authentication/canvas 
        "#{string}==".tr("-_", "+/").unpack("m")[0]
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
