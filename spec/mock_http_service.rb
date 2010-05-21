require 'erb'

module Koala
  module MockHTTPService
    # Mocks all HTTP requests for with koala_spec_with_mocks.rb

    # Mocked values to be included in TEST_DATA used in specs
    ACCESS_TOKEN = '*'
    OAUTH_CODE = 'OAUTHCODE'
    
    # Loads testing data
    TEST_DATA = YAML.load_file(File.join(File.dirname(__FILE__), 'facebook_data.yml'))
    TEST_DATA.merge!('oauth_token' => Koala::MockHTTPService::ACCESS_TOKEN)
    TEST_DATA['oauth_test_data'].merge!('code' => Koala::MockHTTPService::OAUTH_CODE)
    
    # Useful in mock_facebook_responses.yml
    OAUTH_DATA = TEST_DATA['oauth_test_data']
    APP_ID = OAUTH_DATA['app_id']
    SECRET = OAUTH_DATA['secret']
    SUBSCRIPTION_DATA = TEST_DATA["subscription_test_data"]
    
    # Loads the mock response data via ERB to substitue values for TEST_DATA (see oauth/access_token)
    mock_response_file_path = File.join(File.dirname(__FILE__), 'mock_facebook_responses.yml') 
    RESPONSES = YAML.load(ERB.new(IO.read(mock_response_file_path)).result(binding))         
    
    
    def self.included(base)
      base.class_eval do
        
        def self.make_request(path, args, verb, options = {})
          path = 'root' if path == ''
          server = options[:rest_api] ? 'rest_api' : 'graph_api'
          with_token = args.delete('access_token') == ACCESS_TOKEN ? 'with_token' : 'no_token'
          
          # Assume format is always JSON
          args.delete('format')
          
          # Create a hash key for the arguments
          args = args.empty? ? 'no_args' : args.sort{|a,b| a[0].to_s <=> b[0].to_s }.map{|arr| arr.join('=')}.join('&')
          
          begin
            response = RESPONSES[server][path][args][verb][with_token]
            
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
            
            raise "Missing a mock response for #{data_trace}\nAPI PATH: #{[path, args].join('?')}"
          end
          
          response
        end
        
      end # class_eval
    end # included
  end
end