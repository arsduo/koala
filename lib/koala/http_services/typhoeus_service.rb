require "typhoeus" unless defined?(Typhoeus)

module Koala
  module TyphoeusService
    # this service uses Typhoeus to send requests to the graph
    include Typhoeus
    include Koala::HTTPService

    def self.make_request(path, args, verb, options = {})
      # if the verb isn't get or post, send it as a post argument
      args.merge!({:method => verb}) && verb = "post" if verb != "get" && verb != "post"

      # switch any UploadableIOs to the files Typhoeus expects
      args.each_pair {|key, value| args[key] = value.to_file if value.is_a?(UploadableIO)}

      # you can pass arguments directly to Typhoeus using the :typhoeus_options key
      typhoeus_options = {:params => args}.merge(options[:typhoeus_options] || {})

      # if proxy/timeout options aren't passed, check if defaults are set
      typhoeus_options[:proxy] ||= proxy
      typhoeus_options[:timeout] ||= timeout

      # by default, we use SSL only for private requests (e.g. with access token)
      # this makes public requests faster
      prefix = (args["access_token"] || @always_use_ssl || options[:use_ssl]) ? "https" : "http"

      response = Typhoeus::Request.send(verb, "#{prefix}://#{server(options)}#{path}", typhoeus_options)
      Koala::Response.new(response.code, response.body, response.headers_hash)
    end

    protected

    def self.multipart_requires_content_type?
      false # Typhoeus handles multipart file types, we don't have to require it
    end
  end
end