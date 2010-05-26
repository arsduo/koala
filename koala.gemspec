# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{koala}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Koppel, Chris Baclig, Rafi Jacoby, Context Optional"]
  s.date = %q{2010-05-26}
  s.description = %q{Koala is a lightweight, flexible Ruby SDK for Facebook's new Graph API.  It allows read/write access to the Facebook Graph and provides OAuth URLs and cookie validation for Facebook Connect sites; it also supports access-token based interaction with the old REST API.  Koala supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.}
  s.email = %q{alex@alexkoppel.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/graph_api.rb", "lib/http_services.rb", "lib/koala.rb", "lib/realtime_updates.rb", "lib/rest_api.rb"]
  s.files = ["CHANGELOG", "Manifest", "Rakefile", "init.rb", "lib/graph_api.rb", "lib/http_services.rb", "lib/koala.rb", "lib/realtime_updates.rb", "lib/rest_api.rb", "readme.md", "spec/facebook_data.yml", "spec/koala/api_base_tests.rb", "spec/koala/graph_and_rest_api/graph_and_rest_api_no_token_tests.rb", "spec/koala/graph_and_rest_api/graph_and_rest_api_with_token_tests.rb", "spec/koala/graph_api/graph_api_no_access_token_tests.rb", "spec/koala/graph_api/graph_api_with_access_token_tests.rb", "spec/koala/live_testing_data_helper.rb", "spec/koala/net_http_service_tests.rb", "spec/koala/oauth/oauth_tests.rb", "spec/koala/realtime_updates/realtime_updates_tests.rb", "spec/koala/rest_api/rest_api_no_access_token_tests.rb", "spec/koala/rest_api/rest_api_with_access_token_tests.rb", "spec/koala_spec.rb", "spec/koala_spec_helper.rb", "spec/koala_spec_without_mocks.rb", "spec/mock_facebook_responses.yml", "spec/mock_http_service.rb", "koala.gemspec"]
  s.homepage = %q{http://github.com/arsduo/koala}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Koala", "--main", "readme.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{koala}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A lightweight, flexible library for Facebook's new Graph API}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
