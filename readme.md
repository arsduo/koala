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
for logged in users. For example, in Google AppEngine, you could get the
profile of the logged in user with:

    user = Facebook::get_user_from_cookie(self.request.cookies, key, secret)
    if user
       graph = Facebook::GraphAPI(user["oauth_access_token"])
       profile = graph.get_object("me")
       friends = graph.get_connections("me", "friends")
		end

You can see a full AppEngine example application in examples/appengine.
