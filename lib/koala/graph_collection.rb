module Koala
  module Facebook
    class GraphCollection < Array
      # This class is a light wrapper for collections returned
      # from the Graph API.
      #
      # It extends Array to allow direct access to the data colleciton
      # which should allow it to drop in seamlessly.
      #
      # It also allows access to paging information and the
      # ability to get the next/previous page in the collection
      # by calling next_page or previous_page.
      attr_reader :paging
      attr_reader :api

      def initialize(response, api)
        super response["data"]
        @paging = response["paging"]
        @api = api
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
end
