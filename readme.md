Facebook Ruby SDK
====

This client library is designed to support the
[Facebook Graph API](http://developers.facebook.com/docs/api) and the official
[Facebook JavaScript SDK](http://github.com/facebook/connect-js), which is
the canonical way to implement Facebook authentication. You can read more
about the Graph API at [http://developers.facebook.com/docs/api](http://developers.facebook.com/docs/api).

Basic usage:

    graph = Facebook::GraphAPI(oauth_access_token)
    profile = graph.get_object("me")
    friends = graph.get_connections("me", "friends")
    graph.put_object("me", "feed", "I am writing on my wall!")

If you are using the module within a web application with the
[JavaScript SDK](http://github.com/facebook/connect-js), you can also use the
module to use Facebook for login, parsing the cookie set by the JavaScript SDK
for logged in users.

Testing:

To test the Ruby SDK, replace the contests of the tests/access_token file with a valid Facebook access token with write permissions.