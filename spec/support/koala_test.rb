module KoalaTest

  class << self
    attr_accessor :oauth_token, :app_id, :secret, :app_access_token, :code, :session_key
    attr_accessor :oauth_test_data, :subscription_test_data, :search_time
  end

  # Test setup

  def self.setup_test_environment!
    setup_rspec

    activate_vcr!
    Koala.http_service = Koala::MockHTTPService
    setup_test_data(Koala::MockHTTPService::TEST_DATA)
  end

  def self.setup_rspec
    # set up a global before block to set the token for tests
    # set the token up for
    RSpec.configure do |config|
      config.before :each do
        @token = KoalaTest.oauth_token
        allow(Koala::Utils).to receive(:deprecate) # never fire deprecation warnings
        # Clean up Koala config
        Koala.reset_config
      end
    end
  end

  def self.with_vcr(name)
    # Replay recorded HTTP responses instead of using the mock service.
    old_service = Koala.http_service
    Koala.http_service = Koala::HTTPService
    VCR.use_cassette(name) do
      yield
    end
  ensure
    Koala.http_service = old_service
  end

  def self.setup_test_data(data)
    # make data accessible to all our tests
    self.oauth_test_data = data["oauth_test_data"]
    self.subscription_test_data = data["subscription_test_data"]
    self.oauth_token = data["oauth_token"]
    self.app_id = data["oauth_test_data"]["app_id"].to_s
    self.app_access_token = data["oauth_test_data"]["app_access_token"]
    self.secret = data["oauth_test_data"]["secret"]
    self.code = data["oauth_test_data"]["code"]
    self.session_key = data["oauth_test_data"]["session_key"]

    # fix the search time so it can be used in the mock responses
    self.search_time = data["search_time"] || (Time.now - 3600).to_s
  end

  # Data for testing
  def self.user1
    "barackobama"
  end

  def self.user2
    "koppel"
  end

  def self.page
    "facebook"
  end

  def self.activate_vcr!
    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
      c.hook_into :webmock
      c.default_cassette_options = { :record => :none }
    end
  end
end
