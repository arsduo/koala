module Koala
  module Facebook
    class API
      # A light wrapper for collections returned from the Graph API.
      # It extends Array to allow you to page backward and forward through
      # result sets, and providing easy access to paging information.
      class GraphCollection < Array        
        
        # The raw paging information from Facebook (next/previous URLs).
        attr_reader :paging
        # [Koala::Facebook::GraphAPI] the api used to make requests.
        attr_reader :api
        # The entire raw response from Facebook.
        attr_reader :raw_response
    
        # Initialize the Graph Collection array and store various useful information.
        # 
        # @param response the response from Facebook (a hash whose "data" key is an array)
        # @param api the Graph {Koala::Facebook::API API} instance to use to make calls
        #            (usually the API that made the original call).
        #
        # @return [Koala::Facebook::GraphCollection] an initialized GraphCollection 
        #         whose paging, raw_response, and api attributes are populated.
        def initialize(response, api)
          super response["data"]
          @paging = response["paging"]
          @raw_response = response
          @api = api
        end

        # @private
        # Turn the response into a GraphCollection if they're pageable; 
        # if not, return the original response.
        # The Ads API (uniquely so far) returns a hash rather than an array when queried
        # with get_connections. 
        def self.evaluate(response, api)
          response.is_a?(Hash) && response["data"].is_a?(Array) ? self.new(response, api) : response
        end
        
        # defines methods for NEXT and PREVIOUS pages
        %w{next previous}.each do |this|

          # def next_page
          # def previous_page
          define_method "#{this.to_sym}_page" do
            base, args = send("#{this}_page_params")
            base ? @api.get_page([base, args]) : nil
          end

          # def next_page_params
          # def previous_page_params
          define_method "#{this.to_sym}_page_params" do
            return nil unless @paging and @paging[this]
            parse_page_url(@paging[this])
          end
        end
      
        def parse_page_url(url)
          GraphCollection.parse_page_url(url)
        end

        def self.parse_page_url(url)
          match = url.match(/.com\/(.*)\?(.*)/)
          base = match[1]
          args = match[2]
          params = CGI.parse(args)
          new_params = {}
          params.each_pair do |key,value|
            new_params[key] = value.join ","
          end
          [base,new_params]
        end
      end
    end
    
    # @private
    # legacy support for when GraphCollection lived directly under Koala::Facebook    
    GraphCollection = API::GraphCollection
  end
end
