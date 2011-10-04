# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'koala/version'

Gem::Specification.new do |s|
  s.name    = %q{koala}
  s.version = Koala::VERSION
  s.date    = %q{2011-10-04}

  s.summary     = %q{A lightweight, flexible library for Facebook with support for the Graph API, the REST API, realtime updates, and OAuth authentication.}
  s.description = %q{Koala is a lightweight, flexible Ruby SDK for Facebook.  It allows read/write access to the social graph via the Graph and REST APIs, as well as support for realtime updates and OAuth and Facebook Connect authentication.  Koala is fully tested and supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services.}
  s.homepage    = %q{http://github.com/arsduo/koala}

  s.authors = ["Alex Koppel, Chris Baclig, Rafi Jacoby, Context Optional"]
  s.email   = %q{alex@alexkoppel.com}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.extra_rdoc_files = ["readme.md", "CHANGELOG"]
  s.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "Koala"]

  s.require_paths     = ["lib"]

  s.rubygems_version  = %q{1.4.2}

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<multi_json>,      ["~> 1.0"])
      s.add_runtime_dependency(%q<faraday>,  ["~> 0.7.0"])
      s.add_development_dependency(%q<rspec>,     ["~> 2.5"])
      s.add_development_dependency(%q<rake>,      ["~> 0.8.7"])
    else
      s.add_dependency(%q<multi_json>,      ["~> 1.0"])
      s.add_dependency(%q<rspec>,     ["~> 2.5"])
      s.add_dependency(%q<rake>,      ["~> 0.8.7"])
      s.add_dependency(%q<faraday>,  ["~> 0.7.0"])
    end
  else
    s.add_dependency(%q<multi_json>,      ["~> 1.0"])
    s.add_dependency(%q<rspec>,     ["~> 2.5"])
    s.add_dependency(%q<rake>,      ["~> 0.8.7"])
    s.add_dependency(%q<faraday>,  ["~> 0.7.0"])
  end
end
