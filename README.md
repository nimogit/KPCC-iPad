KPCC-iPad
==========

The next-gen KPCC iOS App for iPad. We open-sourced it on March 5th, 2014 at version 1.0.2.


Config
==========
  In order for this app to hook up to the variety of third-party services we use, you're going to have to setup a file 'KPCC/Config.plist'.

  Here's the current state of ours while withholding sensitive data:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>LinkedIn</key>
    <dict>
      <key>AppKey</key>
      <string>*****</string>
      <key>ClientSecret</key>
      <string>*****</string>
    </dict>
    <key>Twitter</key>
    <dict>
      <key>ConsumerKey</key>
      <string>*****</string>
      <key>ConsumerSecret</key>
      <string>*****</string>
    </dict>
    <key>Readability</key>
    <dict>
      <key>ApiKey</key>
      <string>*****</string>
    </dict>
    <key>Desk</key>
    <dict>
      <key>AuthPassword</key>
      <string>*****</string>
      <key>AuthUser</key>
      <string>*****</string>
    </dict>
    <key>AdSettings</key>
    <dict>
      <key>AdGtpId</key>
      <string>*****</string>
      <key>VendorId</key>
      <string>*****</string>
    </dict>
    <key>Flurry</key>
    <dict>
      <key>DebugKey</key>
      <string>*****</string>
      <key>ProductionKey</key>
      <string>*****</string>
    <dict/>
    <key>TestFlight</key>
    <dict>
      <key>iPadKey</key>
      <string>*****</string>
      <key>iPhoneKey</key>
      <string>*****</string>
    </dict>
    <key>Parse</key>
    <dict>
      <key>ClientKey</key>
      <string>*****</string>
      <key>ApplicationId</key>
      <string>*****</string>
    </dict>
  </dict>
  </plist>
  ```


I. Dependencies
===============

  The app relies on several third party dependencies most of which have been included in the repository as inline compilable source but there are several external dependencies that will need to be placed properly into a "../Libraries" directory in order for the project to compile. Here are the dependencies:

   <h3>External Dependencies:</h3>

       Facebook SDK (FacebookSDK.framework) (v3.1.0)
       Parse (Parse.framework) (v1.2.11)

       The current project assumes the following directory structure:
       
       Libraries Â¬
         FacebookSDK Â¬
            FacebookSDK.framework
       	 Parse.framework
	   |
	   |
	   |
	   KPCCRoot Â¬
	     KPCC.xcodeproj
	   |
	   |
	   |
	
   <h3>Inline compilable dependencies:</h3>
	
	    Google DoubleClick for Publishers (v6.8.0)
	    AudioStreamer (Deprecated) - ** This is a legacy library that I originally used for audio streaming but it was replaced by the Cocoa AVPlayer class
	    Flurry (v4.3.2 for iPhone)
	    SBJson (v3.2)
	    TestFlight (v3.0.0)
	
II. Preprocessor Macros
================

   Per usual, preproc macros are used quite a bit throughout the app in order to fence pieces of code, here is a rundown of some of the important ones

   IPAD_VERSION / IPHONE_VERSION
   Use these to denote at compile-time which target idiom is being built. As of right now, its main purpose is to fence off compiling of UIPopoverControllers from the iPhone

   USE_BACKROUND_PERSISTENCE
   Has the app utilize CoreData operations on a background thread to help performance

   SANDBOX_PUSHES
   Use this macro to have the app subscribe to a non-production Parse channel called "sandbox_beta", which will allow for the developer to send push notifications to just the development app.

   STOCK_PLAYER
   This should always be left on. As part of a refactoring, the code should be modified to make the AVPlayer audio streaming code the default behavior without the need of this macro. As it is,
   disabling this macro will cause the app to use the old streamer based on AudioStreamer, which will result in unexpected behavior.

   SUPPORT_LANDSCAPE
   This should also be left on. Disabling it will lock the app to portrait.

   USE_PARSE
   Forces the app to skip any operations related to Parse. Good for taking Parse out of the equation when debugging, but should always be turned on for production builds.

   MOST_VIEWED_STYLE_FETCHING
   This should also always be left on. This makes the app use a specific type of data fetching that displays news in the way we agreed upon with editorial: Fetch all news, but only "feature" (commonly known in house as "embiggening") news that exists in a bucket called "mobile-featured". Disabling this macro will cause unexpected results.

   AGGRESSIVE_DEALLOCATION
   This functionality will force larger images to unload after the app determines the user is finished with them. Otherwise, it's left to the os to return this memory to the stack which oftentimes isn't sufficient.

   TURN_OFF_LOGGING
   Sets NSLog to // at compile-time. This only works assuming your NSLog statement is exactly one line in length, so try to keep to that otherwise you'll get compilation errors.

   VERBOSE_VERSION
   This will display a more detailed version string anywhere in the app where the app's version displays

   PRODUCTION / RELEASE / DEBUG
   Self-explanatory macros

III. App philosophies
=================

   <ol>
    <li>The app uses ARC</li>
    <li>The app uses xib resources for its views</li>
    <li>The app does not use Storyboards</li>
    <li>The app does not use Autolayout</li>
    <li>The app favors delegates and KVO over the NotificationCenter where possible. Where impossible, the app removes the observation as soon as possible</li>
   </ol>
   
IV. App views and hierarchy
=================

   The app is designed slightly unorthodox in that it allows autorotation, but is technically setup only to support portrait. The result is more control for the developer as to what happens on autorotation. Because of this the main view hierarchy is setup as follows:

   <h3>Hierarchy:</h3>

   	Main Window Â¬
     	   SCPRMasterRootViewController Â¬
         	SCPRViewController Â¬
            	   [ Navigation Views ]

   Essentially in this hierarchy we can ignore the Main Window for almost everything. All "window-level" top UI operations like masking the app with a spinner, showing the onboarding flow, having views display over all subviews etc. happen on the SCPRMasterRoot level which you can think of as our window even though technically it's not. The drawer, titlebar, and audio player bar also live as top-level subviews on the SCPRMasterRoot. The app uses SCPRViewController to handle content-related top level switching of what's displaying to the user. SCPRViewController is a monolithic dispatcher that's meant to serve as the viewport for mutable content. All full-screen views (News, Short List, Events etc.) get loaded as subviews of SCPRViewController. Examine the <STRONG>primeUI:newsPath:</STRONG> method in SCPRViewController to see how navigation is handled and rewritten to the screen as the user moves around.

  
   Autorotation as I mentioned is handled in an unorthodox way. The most important element that makes autorotation work in this context is the resizeVector. Each time a view is expected to have a custom behavior when autorotating it's pushed to the resizeVector via the function <STRONG>[[ContentManager shared] pushToResizeVector]</STRONG>. This vector accepts view controllers that adopt the protocol Rotatable. The idea is that every time the app autorotates it will iterate through the resize vector and call pre-rotation and post-rotation code on everything in there, so if you need views to do some custom behavior (like rebuilding a scroller full of views with new dimensions) then it should execute in the handleRotationPre and handleRotationPost methods implemented in the view controller (as part of the protocol). For good a example of this, examine SCPRSingleArticleCollectionViewController's handleRotationPost method where that view simply reloads its articles into the scroller now that it's been resized. The big downside of this system is that the vector needs to be maintained manually, so as soon as a Rotatable view is no longer needed it needs to be popped from the resizeVector using <STRONG>[[ContentManager shared] popFromResizeVector]</STRONG> to ensure unnecessary work isn't executing.
	
	
   Most of the primary views ended up getting their own xib file for Landscape and these are labeled as such (i.e. *Landscape.xib). Some views escaped without needing one as the autorotation and contentResizingMasks were enough to display them adequately in either orientation without the need, but I made a lot of Landscape resources just to handle the nuances of the reorienting. Examine the <STRONG>xibForPlatformWithName:</STRONG> method in the DesignManager class to see how these xibs are automatically loaded based on the orientation of the device.
	
	
V. Titlebar
================

  The titlebar's contents change quite a bit as the user navigates around in the app. The best way to handle this constant changing was to build a navigation mechanism similar to the way the operating system handles its viewController stack. As the user drills deeper into views, the SCPRTitlebarViewController is responsible for pushing the previous state of the titlebar onto a stack, and then restoring the previous state when the user is working his way back up the navigation stack. Observe the <STRONG>morph:container: and pushStyle:</STRONG> methods in SCPRTitlebarViewController and you'll see how the titlebar saves and restores states. This is also a manual process, so the "pop" method of SCPRTitlebarViewController needs to be explicitly called when views are removing themselves from the navigation stack. 

VI. Primary content view controllers
================

  The app is divided into 4 main news sections, and has several other "take-over-the-whole-screen" areas as well:

  Sections:
  <ul>
    <li>News</li>
    <li>The Short List</li>
    <li>Photo & Video</li>
    <li>Live Events</li>
  </ul>
  
  Auxiliary full-screen views:
  <ul>
    <li>Personal Profile/Sign-in section</li>
    <li>Queue view</li>
    <li>Feedback view</li>
  </ul>
  
  Atomic article view:
  <ul> 
   <li>SingleArticleViewController</li>
  </ul>

  <h3>News, Photo & Video, Events</h3>
   
   I'm grouping these together because they are all based on the same base class: SCPRDeluxeNewsViewController. While the appearance of these three views are very similar, there are some fundamental differences in the way table cells are constructed so it warrants noting here some of the bigger differences between them.

   For the "NEWS" section, the cells are built on-the-fly and are reused and redrawn dynamically as the user loads them up. For "PHOTO & VIDEO", and "LIVE EVENTS" the cells are built when the main view loads and no cells are recycled. This was a decision made based on the average quantity of the content that each screen is going to be responsible for. Where News might be eventually responsible of displaying a week's worth of data, the other sections are only drawing from a limited date range and thus won't ever balloon much greater than 15 or 20 stories per page.

   For the "NEWS" section, a cell "map" is built based off of the news that's fetched from our API. The bulk of this happens in the <STRONG>sortNewsData</STRONG> method. This method is responsible for sifting through the news by date, cross-indexing the "featured" bucket to find out if a news story is featured or not, and then building a map of what the table cells are going to look like as the user scrolls through the table. However, no cells are actually allocated during this step. The other two views "PHOTO & VIDEO" and "EVENTS" utilize the <STRONG>buildCells</STRONG> method to build and allocate all of the cells at load-time, and then as the user scrolls through the table they are loaded from a pre-allocated vector that had been storing them. 

   Each SCPRDeluxeNewsViewController is designated with a <STRONG>ScreenContentType</STRONG> variable called contentType. Sift through the code and observe areas where that property is compared (i.e. self.contentType == *** ) to see where other differences between these three views occur.

   I.) The Screen Content Type enum with the relevant types highlighted:

    typedef enum {
      ScreenContentTypeUnknown = 0,
      ScreenContentTypeNewsPage, /* Deprecated */
      ScreenContentTypeDynamicPage, /* Deprecated */
      ScreenContentTypeProgramPage,
      ScreenContentTypeSnapshotPage,
      ScreenContentTypeCompositePage, /* Used for SCPRDeluxeNewsViewController contentType property */
      ScreenContentTypeEventsPage, /* Used for SCPRDeluxeNewsViewController contentType property */
      ScreenContentTypeProfilePage,
      ScreenContentTypeProgramAZPage,
      ScreenContentTypeVideoPhotoPage, /* Used for SCPRDeluxeNewsViewController contentType property */
      ScreenContentTypeUnderConstruction,
      ScreenContentTypeFeedback,
      ScreenContentTypeOnboarding
    } ScreenContentType;

   Cells for these views are based off of several predetermined templates which vary depending on the aspect ratio of the lead image asset being represented in the cell. A call to <STRONG>aspectCodeForContentItem: quality:</STRONG> in the DesignManager will return a string representation that best fits the determined aspect ratio. The proper xib name is built using this string.


  <h3>The Short List</h3>

   The Short List terminology used to be referred to as 'Editions' so The Short List is represented by the classes generally prefixed by SCPREdition*. I was developing these classes right around the time that Breaking Bad was winding down its final 8 episodes so the structures are (poorly) named to represent the way matter is bonded. Unfortunately the SCPREditionCrystal class was deprecated when The Short List came about so the taxonomy breaks down. But what's important is this:

   SCPREditionMineral is a collection of SCPREditionShortList classes (formerly SCPREditionCrystals)

   SCPREditionMolecule is a collection of SCPREditionAtom classes.

So the Mineral and the Molecule are the containers that display a scroller full of their particles: ShortList and Atom respectively. The nice advantage of the SCPREditionShortList class over the SCPREditionCrystal is that it shares its UI with that found in the NEWS table so a single class was able to represent both the standalone section and the top most cell in SCPRDeluxeNewsViewController (of contentType == ScreenContentTypeCompositeNews).

Because the SCPREditionShortListViewController is used in both standalone mode and as the top-most cell of the NEWS section, this distinction is made by the property <STRONG>fromNews</STRONG>. If fromNews == YES then the class is being displayed in the SCPRDeluxeNews context otherwise it is part of a SCPREditionMineralViewController in the 'The Short List' section.

   <h3>QueueViewController</h3>

The SCPRQueueViewController represents the modal view controller that emerges when the button in the lower-right portion of the screen is tapped. When a piece of audio is added to the queue a CoreData managed object of the class <STRONG>Segment</STRONG> is created and assigned an <STRONG>addedToQueueDate</STRONG> and <STRONG>queuePosition</STRONG>. The Queue is then built based on the presence of these Segment objects. Examine the <STRONG>orderedSegmentsForCollection:</STRONG> method in ContentManager to see how the Segments are fetched. The vector returned by this method becomes the representation of the queue used by the SCPRQueueViewController's table. Once a mutable version of this vector is exposed to the table, the table becomes the primary manipulator of the queue. Rearranging of items in the queue, adding, and deleting will trigger the QueueManager to rebuild the queue representation based on the contents of the table in SCPRQueueViewController. The exception to this is adding to the queue which interacts directly with the Segment model.

   <h3>SingleArticleViewController</h3>

 The SingleArticleViewController is used throughout the app to display a single piece of news content. It is used by The Short List, Photo & Video, News, Events, and sometimes standalone to display a breaking news story.

The key parent component of this is the <STRONG>SingleArticleCollectionViewController</STRONG>. This collection view consists of a scroller that at any given time has 3 SingleArticle views loaded: A left-wing, a center, and a right-wing view. This was done to conserve memory when scrolling through very long arrays of news. The trick to this view is redrawing two of the three views every time the scroller is scrolled even though two of the views are offscreen. The view that is not redrawn is the view that's about to come into focus. Because it's already been loaded offscreen there's no need to redraw it when it becomes the center. So it follows that if the user is scrolling left, the right-wing article is not reloaded because it's now the center article and for scrolling right the left-wing article is "protected" from a reload. Examine the <STRONG>setupWithCollection:beginningAtIndex:processIndex:</STRONG> method which will take an array of news and setup your entire view. This method is called every time the <STRONG>scrollViewDidEndDecelerating:</STRONG> is called.

The other piece of this view is that each article is loading a native asset, headline, byline etc for the top portion, but then utilizes a UIWebView to display the body of the article. Because UIWebViews are extremely fussy when it comes to memory allocation and subsequent deallocation, the app has to do some work cleaning up each web view as soon as it's no longer needed. Examine the <STRONG>killContent</STRONG> method of SCPRSingleArticleViewController. Before it does anything it reloads the webview with an empty page, using a full loadRequest. To ensure that there's no race condition between the completion of this request and the deallocation of the entire view, as the view is being killed it's first pushed to a deactivation vector in content manager using the <STRONG>[[ContentManager shared] queueDeactivation:self]</STRONG> method. This ensures the view is retained while its webView is cleaning itself. Once the request is done it unloads some of the other view and makes a strong attempt to zero itself out and finally removes itself from the deactivation queue which should finally allow the system to deallocate it completely. This helps keep the memory footprint down but is far from perfect. Ultimately, Apple needs to do a better job of returning memory used in a UIWebView request back to the stack.

Articles are parsed heavily before getting displayed in the UIWebView. Examine the <STRONG>htmlPageFromBody:article:style:</STRONG> method in FileManager. A rigorous parsing algorithm is put into play to collect "tappable" links and embeds with the Embeditor signature attached to them. Tappable links should never reload the contents of the parent UIWebView so each link on the page is replaced by a special link tag that will open a new in-app UIWebView to display the contents of the link. Moreover, Embeditor tags are replaced with special divs that hide away the contents of the embed and replace them with tappable replacement links. The behavior of these links depend on the data-service of the embed. The default behavior for these embeds is to treat it like any other tappable link and open an in-app webview to display the contents. Examine the <STRONG>collectEmbedded:type:</STRONG> method to see how the raw HTML is parsed for embeds.

VII. Singleton Managers
=======================

Use the suite of singleton managers in order to manage functionality across the app. These nifty classes are available to the entire codebase by invoking the shared instance with [SuchAndSuchManager shared]. I tried to group relevant functionality into each manager but there is some creep so keep that in mind.

<h3>Content Manager</h3>

Handles most everything related to processing news content, managing user settings both locally and in Parse, interacting with CoreData, and image caching.

<h3>Design Manager</h3>

Handles UI related elements like colors, fonts, view factories, and layout functions.

<h3>Network Manager</h3>

Responsible for calls that go out to our SCPR API

<h3>AnalyticsManager</h3>

Handles all things related to app analytics and interfacing with third party sources like TestFlight and Flurry.

<h3>Queue Manager</h3>

An underutilized manager that handles operations related to the audio queue.

<h3>Audio Manager</h3>

Handles operations related to streaming audio and checking the status of the player.

<h3>File Manager</h3>

Deals with a lot of functions that require interacting with files both from the resource bundle and the user sandbox. The bulk of the text parsing and HTML generation went in here as well which may have been better suited for the ContentManager, but, oh well.

<h3>Schedule Manager</h3>

Handles all tasks related to the program air schedule and program reminders.

<h3>Social Manager</h3>

Handles interactions with social logins (Facebook, Twitter, LinkedIn) and the membership API.

<h3>Feedback Manager</h3>

Handles all things related to user feedback from the Feedback screen.

<h3>Utilities</h3>

While technically this is used primarily as a static class I'm grouping it into the singleton managers section because its function is similar. It's basically a set of common operations that need to happen throughout the app. It covers everything from text manipulation to generating pretty strings for dates. Any method that I decided would be useful across the entire app but has no real specific context goes in here.

   
   
