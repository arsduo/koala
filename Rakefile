# Rakefile
require 'rubygems'
require 'rake'
require 'echoe'

# gem management
Echoe.new('koala', '0.7.0') do |p|
  p.summary    = "A lightweight, flexible library for Facebook's new Graph API"
  p.description = "Koala is a lightweight, flexible Ruby SDK for Facebook's new Graph API.  It allows read/write access to the Facebook Graph and provides OAuth URLs and cookie validation for Facebook Connect sites; it also supports access-token based interaction with the old REST API.  Koala supports Net::HTTP and Typhoeus connections out of the box and can accept custom modules for other services."
  p.url            = "http://github.com/arsduo/koala"
  p.author         = ["Alex Koppel", "Chris Baclig", "Rafi Jacoby", "Context Optional"]
  p.email          = "alex@alexkoppel.com"
  p.ignore_pattern = ["tmp/*", "script/*", "pkg/*"]
  p.development_dependencies = []
end