module Koala
  module MockHTTPService
    
    # Mocks all HTTP requests for with koala_spec_with_mocks.rb
    
    data_file_path = File.join(File.dirname(__FILE__), 'mock_facebook_responses.yml')
    DATA = YAML.load_file(data_file_path)
    
    # Access token to be used for specs requiring an access token
    ACCESS_TOKEN = '*'
    
    def self.included(base)
      
      base.class_eval do
        
        # Should return a string with valid (quoted) JSON
        def self.make_request(path, args, verb, options = {})
          path = 'root' if path == ''
          server = options[:rest_api] ? 'rest_api' : 'graph_api'
          with_token = args.delete('access_token') == ACCESS_TOKEN ? 'with_token' : 'no_token'
          
          # Assume format is always JSON
          args.delete('format')
          
          # Create a hash key for the arguments
          args = args.empty? ? 'no_args' : args.sort{|a,b| a[0].to_s <=> b[0].to_s }.map{|arr| arr.join('=')}.join('&')
          
          begin
            response = DATA[server][path][args][verb][with_token]
            
            # Raises an error of with_token/no_token key is missing
            raise NoMethodError unless response
            
          rescue NoMethodError
            # Raises an error message with the place in the data YML
            # to place a mock as well as a URL to request from
            # Facebook's servers for the actual data
            # (Don't forget to replace ACCESS_TOKEN with a real access token)  
            
            data_trace = [server, path, args, verb, with_token] * ': '
            
            args = args == 'no_args' ? '' : "#{args}&"
            args += 'format=json'
            args += "&access_token=#{ACCESS_TOKEN}" if with_token 
            
            raise "Missing a mock data for #{data_trace}\nAPI PATH: #{[path, args].join('?')}"
          end
          
          response
        end
      end # class_eval
    end
  end
end