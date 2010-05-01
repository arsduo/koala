Koala
====

This Ruby client library is designed to support the
[Facebook Graph API](http://developers.facebook.com/docs/api) and the official
[Facebook JavaScript SDK](http://github.com/facebook/connect-js), which is
the canonical way to implement Facebook authentication. You can read more
about the Graph API at [http://developers.facebook.com/docs/api](http://developers.facebook.com/docs/api).

Basic usage:

    graph = Koala::GraphAPI.new(oauth_access_token)
    profile = graph.get_object("me")
    friends = graph.get_connections("me", "friends")
    graph.put_object("me", "feed", :message => "I am writing on my wall!")

If you are using the module within a web application with the
[JavaScript SDK](http://github.com/facebook/connect-js), you can also use the
module to use Facebook for login, parsing the cookie set by the JavaScript SDK
for logged in users.

Testing
-----

Unit tests are provided for Graph API methods.  However, because the Graph API uses access tokens, which expire, you have to provide your own token with stream publishing permissions for the tests.  Insert the token value into the file test/facebook_data.yml, then run the test as follows:
    spec facebook_tests.rb
    
Unit tests for cookie validation and other methods in the OAuth class will be provided shortly.  (You'll also need to add that information into the yml.)