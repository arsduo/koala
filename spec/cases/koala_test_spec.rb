require 'spec_helper'

describe KoalaTest do
  describe ".setup_test_environment!" do
    it "sets up the mock HTTP service and fixture data" do
      allow(KoalaTest).to receive(:setup_rspec)
      expect(KoalaTest).to receive(:activate_vcr!)
      expect(KoalaTest).to receive(:setup_test_data).with(Koala::MockHTTPService::TEST_DATA)

      KoalaTest.setup_test_environment!

      expect(Koala.http_service).to eq(Koala::MockHTTPService)
    end
  end

  describe ".with_vcr" do
    it "uses the HTTP service with a playback-only cassette" do
      KoalaTest.with_vcr("app test accounts") do
        expect(Koala.http_service).to eq(Koala::HTTPService)
        expect(VCR.current_cassette.name).to eq("app test accounts")
        expect(VCR.current_cassette.record_mode).to eq(:none)
      end

      expect(Koala.http_service).to eq(Koala::MockHTTPService)
    end

    it "restores the mock service when an exception is raised" do
      expect do
        KoalaTest.with_vcr("app test accounts") { raise "test failure" }
      end.to raise_error(RuntimeError, "test failure")

      expect(Koala.http_service).to eq(Koala::MockHTTPService)
      expect(VCR.current_cassette).to be_nil
    end

    it "rejects requests that are not in the cassette" do
      expect do
        KoalaTest.with_vcr("app test accounts") do
          Koala::Facebook::API.new.get_object("unrecorded-object")
        end
      end.to raise_error(VCR::Errors::UnhandledHTTPRequestError)

      expect(Koala.http_service).to eq(Koala::MockHTTPService)
    end
  end
end