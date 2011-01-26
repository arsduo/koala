# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{koala}
  s.version = "1.0.0.beta"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Koppel, Chris Baclig, Rafi Jacoby, Context Optional"]
  s.date = %q{2011-01-26}
  s.description = %q{Koala is a lightweight, flexible Ruby SDK for Facebook.  It allows read/write access to the social graph via the Graph API and the older REST API, as well as support for realtime updates and OAuth and Facebook Connect authentication.  Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.}
  s.email = %q{alex@alexkoppel.com}
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "lib/koala.rb", "lib/koala/graph_api.rb", "lib/koala/http_services.rb", "lib/koala/realtime_updates.rb", "lib/koala/rest_api.rb", "lib/koala/test_users.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "Rakefile", "init.rb", "koala.gemspec", "lib/koala.rb", "lib/koala/graph_api.rb", "lib/koala/http_services.rb", "lib/koala/realtime_updates.rb", "lib/koala/rest_api.rb", "lib/koala/test_users.rb", "readme.md", "spec/facebook_data.yml", "spec/koala/api_base_tests.rb", "spec/koala/assets/beach.jpg", "spec/koala/graph_and_rest_api/graph_and_rest_api_no_token_tests.rb", "spec/koala/graph_and_rest_api/graph_and_rest_api_with_token_tests.rb", "spec/koala/graph_api/graph_api_no_access_token_tests.rb", "spec/koala/graph_api/graph_api_tests.rb", "spec/koala/graph_api/graph_api_with_access_token_tests.rb", "spec/koala/graph_api/graph_collection_tests.rb", "spec/koala/live_testing_data_helper.rb", "spec/koala/net_http_service_tests.rb", "spec/koala/oauth/oauth_tests.rb", "spec/koala/realtime_updates/realtime_updates_tests.rb", "spec/koala/rest_api/rest_api_no_access_token_tests.rb", "spec/koala/rest_api/rest_api_tests.rb", "spec/koala/rest_api/rest_api_with_access_token_tests.rb", "spec/koala/test_users/test_users_tests.rb", "spec/koala/typhoeus_service_tests.rb", "spec/koala_spec.rb", "spec/koala_spec_helper.rb", "spec/koala_spec_without_mocks.rb", "spec/mock_facebook_responses.yml", "spec/mock_http_service.rb"]
  s.homepage = %q{http://github.com/arsduo/koala}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Koala"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{koala}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{A lightweight, flexible library for Facebook with support for the Graph API, the old REST API, realtime updates, and OAuth validation.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.0"])
      s.add_runtime_dependency(%q<multipart-post>, [">= 1.0"])
    else
      s.add_dependency(%q<json>, [">= 1.0"])
      s.add_dependency(%q<multipart-post>, [">= 1.0"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.0"])
    s.add_dependency(%q<multipart-post>, [">= 1.0"])
  end
end
