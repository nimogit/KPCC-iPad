Refactoring Proposals
=======================

 This document serves to outline some areas of the code that could use some refactoring for maintenance purposes

I. primeUI
=======================

****** ADDENDUM 12/19/2013 *******
  I decided to begin the first major step of refactoring primeUI by deprecating the method <STRONG>fetchContentForCompositePage</STRONG> in <STRONG>NetworkManager</STRONG>. All of the code to fetch and populate the news page has been migrated into the <STRONG>SCPRDeluxeNewsViewController</STRONG> under a method named <STRONG>fetchContent</STRONG>. As a result, caching of news data has been all but removed for regular news, but performance of the new refactoring scheme was good enough such that we don't really miss the cache. It stands that re-adding a caching system may still be a good idea, but until we really start seeing it bog down in performance then it can probably be left alone.
*********************************************
 
  As mentioned in the developer note, the <STRONG>primeUI:newsPath:</STRONG> method in SCPRViewController has gotten a little unruly. It was originally intended to simplify the process of the flow: User wants to see a screen -> screen needs data from API so app fetches data -> Data is fetched and app can now publish the screen. As the data types required from the API became more complex having a monolithic dispatching system such as primeUI and its subsequent "handleContent" methods got a little sloppy, requiring flags to differentiate between different kinds of API calls. The refactor here is to take the details of data processing away from the SCPRViewController and moving the responsibility to each individual screen to fetch and work on its own data. There's already an example of this in SCPRDeluxeNewsViewController which has a pull-to-refresh widget on its table (when in NEWS mode). When the user pulls to refresh it makes the network call and bypasses the primeUI dispatcher, choosing to be the receiver of the data. I think it would serve to organize the code much better to shift the data fetching and processing responsibilities to the individual view controllers in this way. It would probably result in some opportunity for performance increases as well, allowing for the screen to be loaded up and the data populated asynchronously instead of relying on the dispatcher to wait until all of the data has been fetched and processed before displaying the screen.

II. Landscape
=======================

  Landscape was somewhat of an afterthought so I decided to implement it in the way that made most sense given the following factors: a) We have to support iOS 6 and iOS7, b) we are on a short timeline for this, c) the app doesn't use autolayout and is dependent on xib files. Given these constraints I chose the landscape methodology that I did. However, it might serve to give the app an autolayout treatment and see if more of the main views could be autorotated without the need of a separate xib file for landscape. Moving forward this would greatly reduce development time and be an overall more elegant solution, but Autolayout of course comes with its own set of frustrations so great care would need to be put in place in order to treat the app. As it is, the biggest problem with Landscape as it exists in the app right now is that the app does not support a Landscape orientation until it's fully launched. i.e. it will always launch in portrait and then adjust its orientation after launch. The problem with this is if the user launches in Landscape, we get a sideways splash screen and then because the resizeVector may have lots of work to do we get quite a bit of noise when the user starts a session and the app is frantically working to make the adjustments to the app's orientation after-the-fact. All things considered it's an experience that most people can live with but it would be cleaner if the app supported true landscape orientation and was able to launch as such.

III. "Collection" views
=======================

  I'm referring in this context to Collection views not in the actual iOS UICollectionView sense but rather as the design pattern of there being a series of screens collected into a scroller and navigated through by swiping left and right. Apple has designed a UIPageViewController which I believe recreates this functionality so it might be worth exploring that class to put this together. This "collection" pattern is used in several places in the app but each has its own implementation, so a good refactoring project would be to create a "PageView" style controller that's available to reuse. Currently, SCPRSingleArticleCollectionViewController, SCPREditionMineralViewController, and SCPREditionMoleculeViewController are three distinct views that mimic the exact same behavior and really should be merged to use one generic base class. SCPRSingleArticleCollectionViewController is somewhat of an exception as it uses the 3-stories at a time trick, where at any given time only a left, center, and right article are actually loaded, but perhaps the generic base class could be written to support this design as well.

IV. DONE - Remove STOCK_PLAYER dependency
=======================

  In the beginning, the app used a third-party audio streaming project called AudioStreamer. I thought it might be beneficial to use a streamer that we have low-level code access to for our streaming implementation. This was useful early on but things like having the audio be controllable from the lock screen, or putting the app through AirPlay came into play then the third-party library was proving inadequate. Thus, the STOCK_PLAYER fence was created to allow me to build a new implementation based on AVPlayer but still do stable builds at the drop of a hat by removing the STOCK_PLAYER macro. The AVPlayer implementation is now finished, tested, and is the only pattern that's going to work anymore so really all of the messy legacy code that's dependent on #ifndef STOCK_PLAYER should be removed and the AudioStreamer class can be booted from the code base.

V. Fix the way the drawer stores its data and handles commands
=======================

  The drawer's implementation has some good ideas behind it, but ended up being somewhat of an embarrassingly bad finished project. It builds itself based on json, which is a good idea. However, it still relies on an internal .json file called faketopicschema.json that contains a macro in it that's to be overwritten by the user favorites (since they appear in the drawer once the user has favorited them). This allows for a nice lightweight way to store a representation of the drawer for easy rebuilding, however examining the <STRONG>handleDrawerCommand:</STRONG> one will quickly see just how poorly written that function is. The bottom line is that it works, but right now it is not nearly as scalable as I'd envisioned it was going to be when I first started writing it.
  
VI. Handle setup of SingleArticleViewController UI better
=======================

  This is another class that's gotten unruly. Examine the <STRONG>arrangeContent</STRONG> method and you're in for a wild ride. The problem here is that because we reuse this screen quite a bit throughout the app but in different contexts then the layout changes based on a series of factors:
      
<ol>
  <li>What kind of single article am I? News or a Live Event?</li>
  <li>If I am a Live Event, do I have an RSVP Url?</li>
  <li>Do I have an asset? If so, is it a vertical/portrait asset?</li>
  <li>Do I have audio?</li>
  <li>Is the device in Landscape or portrait?</li>
  <li>Do I have a video or slideshow asset?</li>
</ol>
      
  Once you add up all of these special conditions you end up dealing with quite a bit of customizing of the presentation. arrangeContent attempts to consider all of these different scenarios but the result is a very ugly function with lots of relative layout activity that does and undoes itself throughout the method. Consider the case of the Live Events context where it does all of the arranging for the view at the end of the function after it's already been setup based on all other conditions earlier in the method. An analogy for how inefficient this is would be thinking of setting up a scene in a play. The curtain is down and the stagehands work feverishly to setup a scene that takes place in a hotel. Everything is setup meticulously and the actors take their places, however before the curtain is raised the director says "Ok, this scene is actually on a beach", so the stagehands take everything down and the actors shuffle into their new places and then the curtain is raised. This is unacceptable.
  
VII. Remove dependency on Readability and write our own reduction service
=========================

  We're using the Readability API to reduce articles to be more suitable for mobile consumption. Readability is great but it comes with some rate limiting and it's possible that once the app grows in popularity we're going to exceed this limit and things will break. Some work was started on writing our own parser. Code-named "Uncle Ben's Offbrand Parsing Extravaganza", the experiment was working adequately with a limited set of trusted outside sources but as the number of sources grew, keeping compatibility with my custom parser was taking up too much of my time so we switched back to Readability. To view what's already been done on this front, examine the <STRONG>localReduction:processor:</STRONG> method in NetworkManager. This is the main parsing algorithm that attempts to do what Readability does which is strip an article down to its most basic elements and present it in a simplified form. Because we have the benefit of knowing we're usually going to be pulling content from a relatively small (and explicit) set of sources there are some "cheats" in my code that attempt to map the article styles of each of these sources. However the more and more of these cheats that were required per source, the more it slowed the development of this parser down quite a bit. It deserves another look to see if it can't be abstracted and more cleverly built. You can view a list of these sources in parser_test.html
  
VIII. ArticleStub
=========================

  Right now article caching is turned off. This is because sometimes errors/typos are found after an article is published so the editor will make a quick change and expect that change to reflect across the board. With the cache in place unfortunately there's not enough communication with Outpost to tell that a relevant article needs a refresh in the cache so I just disabled it. I think it might be worth reviving this system somehow, though do some experiments with load times and see if it's worth it. Last I checked the app <I>felt</I> faster when it was reloading articles from the cache instead of re-parsing it and rebuilding it as the user swiped through, but the savings might not actually be that great so before devising a system where a cache like this is used, do some tests to see how much of a performance benefit we actually get from it. Not only is there a debate to be had about the performance gain vs. dev-time cost, but there's also a debate surrounding the UX as to how often the user is actually going to ever be viewing the same article twice. We as testers and developers of the app need to scroll through these articles numerous times to ensure all is working and loading right, but in the wild we have to ask ourselves how often a user will actually ever come across the same article in the SingleArticleViewController context.
      
  A more useful appropriation for the ArticleStub domain class might be when it's time to implement a "Save for Later" mechanism. At this point you can base the persisted article on the ArticleStub class as it contains all of the deflated information necessary to re-inflate the article at a later time.

IX. Embiggening bucket slows down performance
=========================

  This actually isn't something the app is going to have much control over unfortunately. When the app loads up it needs to call the API for a bucket of content called <STRONG>mobile-featured</STRONG>. This endpoint returns a bucket full of curated news stories that are going to be "featured" or "embiggened" in the main news feed. As this list grows in size it places more work on the backend to consolidate them from their different areas across Outpost and deliver them neatly into a sorted list. The best thing to do is make sure this bucket remains lean. Keep in mind that the app is really not capable at this point of displaying news content that will be much older than 5 or 6 days, however without proper maintenance the mobile-featured bucket will grow to > 40 articles, many of which will be older than a month. Keeping this bucket to about 10 articles or less (coincidentally, approximately a week's worth of stories) is paramount.

  If it stands that this bucket is not being maintained regularly as time wears on, it might be worth suggesting an alternative way to feature news in the app. The performance lag is very noticeable when this list grows.

      
