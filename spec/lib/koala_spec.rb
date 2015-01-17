require 'spec_helper'

describe Koala do
  it "has an http_service accessor" do
    expect(Koala).to respond_to(:http_service)
    expect(Koala).to respond_to(:http_service=)
  end

  describe "constants" do
    it "has a version" do
      expect(Koala.const_defined?("VERSION")).to be_truthy
    end
  end

  context "for deprecated services" do
    before :each do
      @service = Koala.http_service
    end

    after :each do
      Koala.http_service = @service
    end

    it "invokes deprecated_interface if present" do
      mock_service = double("http service")
      expect(mock_service).to receive(:deprecated_interface)
      Koala.http_service = mock_service
    end

    it "does not set the service if it's deprecated" do
      mock_service = double("http service")
      allow(mock_service).to receive(:deprecated_interface)
      Koala.http_service = mock_service
      expect(Koala.http_service).to eq(@service)
    end

    it "sets the service if it's not deprecated" do
      mock_service = double("http service")
      Koala.http_service = mock_service
      expect(Koala.http_service).to eq(mock_service)
    end
  end

  describe "make_request" do
    it "passes all its arguments to the http_service" do
      path = "foo"
      args = {:a => 2}
      verb = "get"
      options = {:c => :d}

      expect(Koala.http_service).to receive(:make_request).with(path, args, verb, options)
      Koala.make_request(path, args, verb, options)
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(Koala.configuration).to be_a Koala::Configuration
    end

    it 'memoizes @configuration' do
      config = Koala.configuration
      expect(config.object_id).to eq Koala.configuration.object_id
    end
  end

  describe '.configure' do
    it 'yields a Configuration instance' do
      expect { |b|
        Koala.configure(&b)
      }.to yield_with_args(Koala::Configuration)
    end
  end

  describe '.reset' do
    before do
      Koala.configure do |config|
        config.allow_array_parameters = true
      end
    end

    it 'resets the configuration' do
      Koala.reset
      expect(Koala.configuration.allow_array_parameters).to eq false
    end
  end
end
