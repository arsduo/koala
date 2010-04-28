require 'facebook_test_suite'

# run the tests with Typhoeus
puts "Running Typhoeus tests"
$service = Facebook::TyphoeusService
Test::Unit::UI::Console::TestRunner.run(FacebookTestSuite)