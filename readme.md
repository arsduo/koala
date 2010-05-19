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

Koala now supports the old-school REST API using OAuth access tokens; to use this, instantiate your class using the RestAPI class:

	api = Koala::Facebook::RestAPI.new(oauth_access_token)

The RestAPI class provides an fql\_query method that you can use to make FQL calls, as well as a generic REST API accessor.  We reserve the right to expand the built-in REST API coverage to additional methods in the future, depending on how fast Facebook moves to fill in the gaps.  (If you want the power of both APIs in the palm of your hand, try out the GraphAndRestAPI class.)

See examples, ask questions
-----
Some resources to help you as you play with Koala and the Graph API:
* Complete Koala documentation <a href="http://wiki.github.com/arsduo/koala/">on the wiki</a>
* The <a href="http://groups.google.com/group/koala-users">Koala users group</a> on Google Groups, the place for your Koala and API questions
* The Koala-powered <a href="http://oauth.twoalex.com" target="_blank">OAuth Playground</a>, where you can easily generate OAuth access tokens and any other data needed to test out the APIs or OAuth

Testing
-----

Unit tests are provided for all of Koala's methods; however, because the OAuth access tokens and cookies expire, you have to provide some of your own data: a valid OAuth access token with publish\_stream and read\_stream permissions and an OAuth code that can be used to generate an access token.  (The file also provides valid values for other tests, which you're welcome to sub out for data specific to your own application.)

Insert the required values into the file test/facebook_data.yml, then run the test as follows:
    spec koala_tests.rb