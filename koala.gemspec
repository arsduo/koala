# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{koala}
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Koppel, Rafi Jacoby, Context Optional"]
  s.date = %q{2010-05-04}
  s.description = %q{Koala is a lightweight, flexible Ruby SDK for Facebook's new Graph API.  It allows read/write access to the Facebook Graph and provides OAuth URLs and cookie validation for Facebook Connect sites.  Koala supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.}
  s.email = %q{alex@alexkoppel.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/http_services.rb", "lib/koala.rb"]
  s.files = ["CHANGELOG", "Manifest", "Rakefile", "init.rb", "lib/http_services.rb", "lib/koala.rb", "readme.md", "test/facebook_data.yml", "test/koala/facebook_no_access_token_tests.rb", "test/koala/facebook_with_access_token_tests.rb", "test/koala_tests.rb", "koala.gemspec"]
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
