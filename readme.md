Koala
====
Koala (<a href="http://github.com/arsduo/koala" target="_blank">http://github.com/arsduo/koala</a>) is a new Facebook Graph library for Ruby.  We wrote Koala with four goals: 

* Lightweight: Koala should be as light and simple as Facebook’s own new libraries, providing API accessors and returning simple JSON.  (We clock in, with comments, just over 300 lines of code.)
* Fast: Koala should, out of the box, be quick. In addition to supporting the vanilla Ruby networking libraries, it natively supports Typhoeus, our preferred gem for making fast HTTP requests. Of course, That brings us to our next topic:
* Flexible: Koala should be useful to everyone, regardless of their current configuration.  (We have no dependencies beyond the JSON gem.  Koala also has a built-in mechanism for using whichever HTTP library you prefer to make requests against the graph.)
* Tested: Koala should have complete test coverage, so you can rely on it.  (By the time you read this the final tests are being written.)

Basic usage:

    graph = Koala::Facebook::GraphAPI.new(oauth_access_token)
    profile = graph.get_object("me")
    friends = graph.get_connections("me", "friends")
    graph.put_object("me", "feed", :message => "I am writing on my wall!")

If you're using Koala within a web application with the Facebook
[JavaScript SDK](http://github.com/facebook/connect-js), you can use the Koala::Facebook::OAuth class 
to parse the cookies set by the JavaScript SDK for logged in users.

FQL and the old-school REST API
-----
Where the Graph API and the old REST API overlap, you should choose the Graph API.  Unfortunately, that overlap is far from complete, and there are many important API calls -- including fql.query -- that can't yet be done via the Graph.  

Koala now supports the old-school REST API using OAuth access tokens; to use this, instantiate your class using the GraphAndRestAPI class:

	api = Koala::Facebook::GraphAndRestAPI.new(oauth_access_token)

The GraphAndRestAPI class provides access to all the Graph API methods, as well as an fql method that you can use to make FQL calls.  (You can pass the :rest\_api => true option to the api method to make REST API calls; check out lib/rest\_api.rb to see how it's done.)  We reserve the right to expand the built-in REST API coverage to additional methods in the future, depending on how fast Facebook moves to fill in the gaps.  

Examples and More Details 
-----
Complete Koala documentation can now be found <a href="http://wiki.github.com/arsduo/koala/">on the wiki</a>!

You can easily generate OAuth access tokens and any other data needed to play with the Graph API or OAuth at the Koala-powered <a href="http://oauth.twoalex.com" target="_blank">OAuth Playground</a>.


Testing
-----

Unit tests are provided for all of Koala's methods; however, because the OAuth access tokens and cookies expire, you have to provide some of your own data: a valid OAuth access token with publish_stream and read_stream permissions and an OAuth code that can be used to generate an access token.  (The file also provides valid values for other tests, which you're welcome to sub out for data specific to your own application.)

Insert the required values into the file test/facebook_data.yml, then run the test as follows:
    spec koala_tests.rb
    

Coming Soon
-----
* Support for real-time updates

Known Issues
-----
1. gem install koala produces "Could not find main page readme.md" message