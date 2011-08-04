unless ENV['LIVE']
  # By default the Koala specs are run using stubs for HTTP requests
  #
  # Valid OAuth token and code are not necessary to run these
  # specs.  Because of this, specs do not fail due to Facebook
  # imposed rate-limits or server timeouts.
  #
  # However as a result they are more brittle since
  # we are not testing the latest responses from the Facebook servers.
  # Therefore, to be certain all specs pass with the current
  # Facebook services, run koala_spec_without_mocks.rb.
  Koala.http_service = Koala::MockHTTPService  
  KoalaTest.setup_test_data(Koala::MockHTTPService::TEST_DATA)
else
  # Runs Koala specs through the Facebook servers
  #
  # load testing data (see note in readme.md)  
  KoalaTest.setup_test_data(YAML.load_file(File.join(File.dirname(__FILE__), '../fixtures/facebook_data.yml')))
  
  if adapter = ENV['ADAPTER']
    # allow live tests with different adapters
    begin
      require adapter
      Faraday.default_adapter = adapter.to_sym
      puts "Using Faraday adapter #{adapter}."
    rescue LoadError
      puts "Unable to load adapter #{adapter}, using Net::HTTP."
    end
  end
    
  # use a test user unless the developer wants to test against a real profile
  if token = KoalaTest.oauth_token
    KoalaTest.validate_user_info(token)
  else
    KoalaTest.setup_test_users
  end
end

# set up a global before block to set the token for tests
# set the token up for 
RSpec.configure do |config|
  config.before :each do
    @token = KoalaTest.oauth_token
  end
  
  config.after :each do
    # clean up any objects posted to Facebook
    if @temporary_object_id && !KoalaTest.mock_interface?
      api = @api || (@test_users ? @test_users.graph_api : nil)
      raise "Unable to locate API when passed temporary object to delete!" unless api

      # wait 10ms to allow Facebook to propagate data so we can delete it
      sleep(0.01)
      
      # clean up any objects we've posted
      result = (api.delete_object(@temporary_object_id) rescue false)
      # if we errored out or Facebook returned false, track that
      puts "Unable to delete #{@temporary_object_id}: #{result} (probably a photo or video, which can't be deleted through the API)" unless result
    end
  end
end


