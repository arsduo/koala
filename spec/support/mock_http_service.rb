require 'erb'
require 'yaml'

module Koala
  module MockHTTPService
    include Koala::HTTPService

    # fix our specs to use ok_json, so we always get the same results from to_json
    MultiJson.use :ok_json

    # Mocks all HTTP requests for with koala_spec_with_mocks.rb
    # Mocked values to be included in TEST_DATA used in specs
    ACCESS_TOKEN = '*'
    APP_ACCESS_TOKEN = "**"
    OAUTH_CODE = 'OAUTHCODE'

    # Loads testing data
    TEST_DATA = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'fixtures', 'facebook_data.yml'))
    TEST_DATA.merge!('oauth_token' => Koala::MockHTTPService::ACCESS_TOKEN)
    TEST_DATA['oauth_test_data'].merge!('code' => Koala::MockHTTPService::OAUTH_CODE)
    TEST_DATA['search_time'] = (Time.now - 3600).to_s

    # Useful in mock_facebook_responses.yml
    OAUTH_DATA = TEST_DATA['oauth_test_data']
    OAUTH_DATA.merge!({
      'app_access_token' => APP_ACCESS_TOKEN,
      'session_key' => "session_key",
      'multiple_session_keys' => ["session_key", "session_key_2"]
    })
    APP_ID = OAUTH_DATA['app_id']
    SECRET = OAUTH_DATA['secret']
    SUBSCRIPTION_DATA = TEST_DATA["subscription_test_data"]

    # Loads the mock response data via ERB to substitue values for TEST_DATA (see oauth/access_token)
    mock_response_file_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'mock_facebook_responses.yml')
    RESPONSES = YAML.load(ERB.new(IO.read(mock_response_file_path)).result(binding))

    def self.make_request(path, args, verb, options = {})
      path = 'root' if path == '' || path == '/'
      verb ||= 'get'
      server = options[:rest_api] ? 'rest_api' : 'graph_api'
      token = args.delete('access_token')
      with_token = (token == ACCESS_TOKEN || token == APP_ACCESS_TOKEN) ? 'with_token' : 'no_token'

      # Assume format is always JSON
      args.delete('format')

      # Create a hash key for the arguments
      args = create_params_key(args)

      begin
        response = RESPONSES[server][path][args][verb][with_token]

        # Raises an error of with_token/no_token key is missing
        raise NoMethodError unless response

        # create response class object
        response_object = if response.is_a? String
            Koala::HTTPService::Response.new(200, response, {})
          else
            Koala::HTTPService::Response.new(response["code"] || 200, response["body"] || "", response["headers"] || {})
          end

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

      response_object
    end

    def self.encode_params(*args)
      # use HTTPService's encode_params
      HTTPService.encode_params(*args)
    end

    protected

    def self.create_params_key(params_hash)
      if params_hash.empty?
        'no_args'
      else
        params_hash.sort{ |a,b| a[0].to_s <=> b[0].to_s}.map do |arr|
          arr[1] = '[FILE]' if arr[1].kind_of?(Koala::UploadableIO)
          arr.join('=')
        end.join('&')
      end
    end
  end
end
