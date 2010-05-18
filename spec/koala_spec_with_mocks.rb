require 'koala_spec_helper'
require 'mock_http_service'

# Runs Koala specs using stubs for HTTP requests
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

$testing_data = Koala::MockHTTPService::TEST_DATA