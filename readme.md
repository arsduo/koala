[![Build Status](https://secure.travis-ci.org/arsduo/koala.png)](http://travis-ci.org/arsduo/koala)
[![Code Climate](https://codeclimate.com/github/arsduo/koala.png)](https://codeclimate.com/github/arsduo/koala)

Koala
====
[Koala](http://github.com/arsduo/koala) is a Facebook library for Ruby, supporting the Graph API (including the batch requests and photo uploads), the REST API, realtime updates, test users, and OAuth validation.  We wrote Koala with four goals:

* Lightweight: Koala should be as light and simple as Facebook’s own libraries, providing API accessors and returning simple JSON.
* Fast: Koala should, out of the box, be quick. Out of the box, we use Facebook's faster read-only servers when possible and if available, the Typhoeus gem to make snappy Facebook requests.  Of course, that brings us to our next topic:
* Flexible: Koala should be useful to everyone, regardless of their current configuration.  We support JRuby, Rubinius, and REE as well as vanilla Ruby (1.8.7, 1.9.2, 1.9.3, and 2.0.0), and use the Faraday library to provide complete flexibility over how HTTP requests are made.
* Tested: Koala should have complete test coverage, so you can rely on it.  Our test coverage is complete and can be run against either mocked responses or the live Facebook servers; we're also on [Travis CI](http://travis-ci.org/arsduo/koala/).

Installation
---

In Bundler:
```ruby
gem "koala", "~> 2.0"
```

Otherwise:
```bash
[sudo|rvm] gem install koala
```

Upgrading to 2.0
---------

Koala 2.0 is not a major refactor, but rather a set of small, mostly internal
refactors, which should not require significant changes by users. See changelog.md for more
details.

Graph API
---------

The Graph API is the simple, slick new interface to Facebook's data.
Using it with Koala is quite straightforward.  First, you'll need an access token, which you can get through
Facebook's [Graph API Explorer](https://developers.facebook.com/tools/explorer) (click on 'Get Access Token').
Then, go exploring:

```ruby
@graph = Koala::Facebook::API.new(oauth_access_token)

profile = @graph.get_object("me")
friends = @graph.get_connections("me", "friends")
@graph.put_connections("me", "feed", :message => "I am writing on my wall!")

# Three-part queries are easy too!
@graph.get_connections("me", "mutualfriends/#{friend_id}")

# You can use the Timeline API:
# (see https://developers.facebook.com/docs/beta/opengraph/tutorial/)
@graph.put_connections("me", "namespace:action", :object => object_url)

# For extra security (recommended), you can provide an appsecret parameter,
# tying your access tokens to your app secret.
# (See https://developers.facebook.com/docs/reference/api/securing-graph-api/
# You'll need to turn on 'Require proof on all calls' in the advanced section
# of your app's settings when doing this.
@graph = Koala::Facebook::API.new(oauth_access_token, app_secret)

# Facebook is now versioning their API. # If you don't specify a version, Facebook
# will default to the oldest version your app is allowed to use. Note that apps
# created after f8 2014 *cannot* use the v1.0 API. See
# https://developers.facebook.com/docs/apps/versions for more information.
#
# You can specify version either globally:
Koala.config.api_version = "v2.0"
# or on a per-request basis
@graph.get_object("me", {}, api_version: "v2.0")
```

The response of most requests is the JSON data returned from the Facebook servers as a Hash.

When retrieving data that returns an array of results (for example, when calling `API#get_connections`)
a GraphCollection object will be returned, which makes it easy to page through the results:

```ruby
# Returns the feed items for the currently logged-in user as a GraphCollection
feed = @graph.get_connections("me", "feed")
feed.each {|f| do_something_with_item(f) } # it's a subclass of Array
next_feed = feed.next_page

# You can also get an array describing the URL for the next page: [path, arguments]
# This is useful for storing page state across multiple browser requests
next_page_params = feed.next_page_params
page = @graph.get_page(next_page_params)
```

You can also make multiple calls at once using Facebook's batch API:
```ruby
# Returns an array of results as if they were called non-batch
@graph.batch do |batch_api|
  batch_api.get_object('me')
  batch_api.put_wall_post('Making a post in a batch.')
end
```

You can pass a "post-processing" block to each of Koala's Graph API methods. This is handy for two reasons:

1. You can modify the result returned by the Graph API method:

        education = @graph.get_object("me") { |data| data['education'] }
        # returned value only contains the "education" portion of the profile

2. You can consume the data in place which is particularly useful in the batch case, so you don't have to pull
the results apart from a long list of array entries:

        @graph.batch do |batch_api|
          # Assuming you have database fields "about_me" and "photos"
          batch_api.get_object('me')                {|me|     self.about_me = me }
          batch_api.get_connections('me', 'photos') {|photos| self.photos   = photos }
        end

Check out the wiki for more details and examples.

The REST API
-----
Where the Graph API and the old REST API overlap, you should choose the Graph API.  Unfortunately, that overlap is far from complete, and there are many important API calls that can't yet be done via the Graph.

Fortunately, Koala supports the REST API using the very same interface; to use this, instantiate an API:
```ruby
@rest = Koala::Facebook::API.new(oauth_access_token)

@rest.fql_query(my_fql_query) # convenience method
@rest.fql_multiquery(fql_query_hash) # convenience method
@rest.rest_call("stream.publish", arguments_hash) # generic version
```

Of course, you can use the Graph API methods on the same object -- the power of two APIs right in the palm of your hand.
```ruby
@api = Koala::Facebook::API.new(oauth_access_token)
fql = @api.fql_query(my_fql_query)
@api.put_wall_post(process_result(fql))
```

Configuration
----
You can change the host that koala makes requests to (point to a mock server, apigee, runscope etc..)
```ruby
# config/initializers/koala.rb
require 'koala'

Koala.configure do |config|
  config.graph_server = 'my-graph-mock.mysite.com'
  # other common options are `rest_server` and `dialog_host`
  # see lib/koala/http_service.rb
end
```

Of course the defaults are the facebook endpoints and you can additionally configure the beta
tier and video upload matching and replacement strings.

OAuth
-----
You can use the Graph and REST APIs without an OAuth access token, but the real magic happens when you provide Facebook an OAuth token to prove you're authenticated.  Koala provides an OAuth class to make that process easy:
```ruby
@oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
```

If your application uses Koala and the Facebook [JavaScript SDK](http://github.com/facebook/facebook-js-sdk) (formerly Facebook Connect), you can use the OAuth class to parse the cookies:
```ruby
# parses and returns a hash including the token and the user id
# NOTE: this method can only be called once per session, as the OAuth code
# Facebook supplies can only be redeemed once.  Your application must handle
# cross-request storage of this information; you can no longer call this method
# multiple times.
@oauth.get_user_info_from_cookies(cookies)
```
And if you have to use the more complicated [redirect-based OAuth process](http://developers.facebook.com/docs/authentication/), Koala helps out there, too:

```ruby
# generate authenticating URL
@oauth.url_for_oauth_code
# fetch the access token once you have the code
@oauth.get_access_token(code)
```

You can also get your application's own access token, which can be used without a user session for subscriptions and certain other requests:
```ruby
@oauth.get_app_access_token
```
For those building apps on Facebook, parsing signed requests is simple:
```ruby
@oauth.parse_signed_request(signed_request_string)
```
Or, if for some horrible reason, you're still using session keys, despair not!  It's easy to turn them into shiny, modern OAuth tokens:
```ruby
@oauth.get_token_from_session_key(session_key)
@oauth.get_tokens_from_session_keys(array_of_session_keys)
```
That's it!  It's pretty simple once you get the hang of it.  If you're new to OAuth, though, check out the wiki and the OAuth Playground example site (see below).

Real-time Updates
-----
Sometimes, reaching out to Facebook is a pain -- let it reach out to you instead.  The Graph API allows your application to subscribe to real-time updates for certain objects in the graph; check the [official Facebook documentation](http://developers.facebook.com/docs/api/realtime) for more details on what objects you can subscribe to and what limitations may apply.

Koala makes it easy to interact with your applications using the RealtimeUpdates class:
```ruby
@updates = Koala::Facebook::RealtimeUpdates.new(:app_id => app_id, :secret => secret)
```
You can do just about anything with your real-time update subscriptions using the RealtimeUpdates class:
```ruby
# Add/modify a subscription to updates for when the first_name or last_name fields of any of your users is changed
@updates.subscribe("user", "first_name, last_name", callback_url, verify_token)

# Get an array of your current subscriptions (one hash for each object you've subscribed to)
@updates.list_subscriptions

# Unsubscribe from updates for an object
@updates.unsubscribe("user")
```
And to top it all off, RealtimeUpdates provides a static method to respond to Facebook servers' verification of your callback URLs:
```ruby
# Returns the hub.challenge parameter in params if the verify token in params matches verify_token
Koala::Facebook::RealtimeUpdates.meet_challenge(params, your_verify_token)
```
For more information about meet_challenge and the RealtimeUpdates class, check out the Real-Time Updates page on the wiki.

Test Users
-----

We also support the test users API, allowing you to conjure up fake users and command them to do your bidding using the Graph or REST API:
```ruby
@test_users = Koala::Facebook::TestUsers.new(:app_id => id, :secret => secret)
user = @test_users.create(is_app_installed, desired_permissions)
user_graph_api = Koala::Facebook::API.new(user["access_token"])
# or, if you want to make a whole community:
@test_users.create_network(network_size, is_app_installed, common_permissions)
```
Talking to Facebook
-----

Koala uses Faraday to make HTTP requests, which means you have complete control over how your app makes HTTP requests to Facebook.  You can set Faraday options globally or pass them in on a per-request (or both):
```ruby
# Set an SSL certificate to avoid Net::HTTP errors
Koala.http_service.http_options = {
  :ssl => { :ca_path => "/etc/ssl/certs" }
}
# or on a per-request basis
@api.get_object(id, args_hash, { :request => { :timeout => 10 } })
```
The <a href="https://github.com/arsduo/koala/wiki/HTTP-Services">HTTP Services wiki page</a> has more information on what options are available, as well as on how to configure your own Faraday middleware stack (for instance, to implement request logging).

See examples, ask questions
-----

Some resources to help you as you play with Koala and the Graph API:

* Complete Koala documentation <a href="https://github.com/arsduo/koala/wiki">on the wiki</a>
* Facebook's <a href="http://facebook.stackoverflow.com/">Stack Overflow site</a> is a stupendous place to ask questions, filled with people who will help you figure out what's up with the Facebook API.
* Facebook's <a href="http://developers.facebook.com/tools/explorer/">Graph API Explorer</a>, where you can play with the Graph API in your browser
* The Koala-powered <a href="http://oauth.twoalex.com" target="_blank">OAuth Playground</a>, where you can easily generate OAuth access tokens and any other data needed to test out the APIs or OAuth
* Follow Koala on <a href="http://www.facebook.com/pages/Koala/315368291823667">Facebook</a> and <a href="https://twitter.com/#!/koala_fb">Twitter</a> for SDK updates and occasional news about Facebook API changes.

*Note*: I use the Koala issues tracker on Github to triage and address issues
with the gem itself; if you need help using the Facebook API, the above
resources will be far more effective. Depending on how much time I have, Github
issues filed about how to use the Facebook API may be closed with a reference
to the Facebook Stack Overflow page.

Testing
-----

Unit tests are provided for all of Koala's methods.  By default, these tests run against mock responses and hence are ready out of the box:
```bash
# From anywhere in the project directory:
bundle exec rake spec
```

You can also run live tests against Facebook's servers:
```bash
# Again from anywhere in the project directory:
LIVE=true bundle exec rake spec
# you can also test against Facebook's beta tier
LIVE=true BETA=true bundle exec rake spec
```
By default, the live tests are run against test users, so you can run them as frequently as you want.  If you want to run them against a real user, however, you can fill in the OAuth token, code, and access\_token values in spec/fixtures/facebook_data.yml.  See the wiki for more details.
