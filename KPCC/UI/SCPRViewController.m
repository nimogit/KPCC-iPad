//
//  SCPRViewController.m
//  KPCC
//
//  Created by Ben on 4/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRViewController.h"
#import "global.h"
#import "domain.h"
#import "SCPRShadowingView.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRNewsPageContainerController.h"
#import "SCPRWebNewsContentViewController.h"
#import "SCPRBCVideoContentViewController.h"
#import "SCPRProgramPageViewController.h"
#import "SCPREditionCrystalViewController.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRSimpleNewsViewController.h"
#import "SCPREventsOverviewViewController.h"
#import "SCPRProfileViewController.h"
#import "SCPRProgramAZViewController.h"
#import "SCPRProgramNavigatorViewController.h"
#import "SCPRDeluxeNewsViewController.h"
#import "SCPRUnderConstructionViewController.h"
#import "SCPRFeedbackViewController.h"
#import "SCPRCompositeNewsViewController.h"
#import "SCPREditionMineralViewController.h"
#import "SCPROnboardingFlowViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRDrawerViewController.h"

// Suppress this warning as we want to be able to simulate an exception with [self functionThatDoesntExist] without looking at an annoying warning for it
#pragma clang diagnostic ignored "-Wincomplete-implementation"

static NSString *kOndemandURL = @"http://media.scpr.org/audio/upload/2013/04/04/Smuggling.mp3";

@interface SCPRViewController ()

@end

@implementation SCPRViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
#ifdef DEBUG
#if TARGET_IPHONE_SIMULATOR
  //[self processProgramImagesInBackground];
#endif
#endif
  
  self.playerWidget = [[SCPRPlayerWidgetViewController alloc]
                       initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRPlayerWidgetViewController"]
                       bundle:nil];
  
  self.playerWidget.parentContainer = self;
  self.contentVector = [[NSMutableArray alloc] init];
  self.playerWidget.view.alpha = 0.0;
  
  if ( [Utilities isIOS7] ) {
    self.mainPageScroller.center = CGPointMake(self.mainPageScroller.center.x,
                                               self.mainPageScroller.center.y+20.0);
    
    
  } else {
    self.mainPageScroller.frame = CGRectMake(self.mainPageScroller.frame.origin.x,
                                             self.mainPageScroller.frame.origin.y,
                                             self.mainPageScroller.frame.size.width,
                                             self.mainPageScroller.frame.size.height+20.0);
  }
  
  NSLog(@"Main paging area : %1.1f",self.mainPageScroller.frame.size.height);
  
  self.mainPageScroller.scrollEnabled = NO;
  self.globalShareDrawer = [[SCPRShareDrawerViewController alloc]
                            initWithNibName:[[DesignManager shared]
                                             xibForPlatformWithName:@"SCPRShareDrawerViewController"]
                            bundle:nil];
  [self.globalShareDrawer buildCells];
  
  
  [self.view addSubview:self.playerWidget.view];
  [self.playerWidget prime];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drawerOpened)
                                               name:@"drawer_opened"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drawerClosed)
                                               name:@"drawer_closed"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(respin)
                                               name:@"favorites_modified"
                                             object:nil];
  
  self.decorativeStripe.backgroundColor = [[DesignManager shared] kpccOrangeColor];
  
  [self globalInit];
  [self placeShareDrawer];
  [self.playerWidget quietMinimize];
  
  [[ContentManager shared] filterPrograms:nil];
  
}

- (void)viewWillAppear:(BOOL)animated {

}

- (void)viewDidAppear:(BOOL)animated {

  
  
}

- (void)respin {
  
  [self buildProgramPages:YES];
  
}

/*****************************************************************************
 -- Developer Note --
 primeUI was the original dispatch method I was going to use to control a data flow to each area of the app. In the early going
 it was serviceable because most of the screens were following a fairly repetitive data routine: User wants a screen, screen needs to fetch
 data from KPCC, app will process that data after fetching and then present the appropriate screen with that data. As the app became
 more complex, it became obvious that it might have been easier to assign the specifics of the data handling to each individual screen
 and not use a monolithic dispatching system, but I decided to continue supporting this dispatcher. If there's a nice refactoring project
 to be undertaken it would be to make primeUI only responsible for loading up the screens onto the main viewport, and then having the specific
 controllers handle all processing of data (see the ContentProcessor protocol). SCPRViewController adopts the <ContentProcessor> protocol, but so
 do some of its children. So sometimes data is fetched directly from the child and processed henceforth (i.e. pull-to-refresh in SCPRDeluxeViewController). It probably serves the app at this point to have all children take care of their own data instead of using the
 monolithic handleProcessedContent: methods implemented in this class.  -- BH
 */
- (void)primeUI:(ScreenContentType)contentType newsPath:(NSString *)newsPath {
  
  self.currentNewsType = contentType;

  [[[Utilities del] globalTitleBar] morph:BarTypeDrawer container:nil];
  [[ContentManager shared] setFlipBackToPageOne:YES];
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  
   if ( newsPath ) {
     self.newsPath = newsPath;
   } else {
     self.newsPath = @"all_content";
   }
  
  
  [[AnalyticsManager shared] setScreenContent:contentType];
  
  [root.view bringSubviewToFront:root.cloakView];
  
   [UIView animateWithDuration:0.3 animations:^{
     
     [[[Utilities del] masterRootController] fullCloak];
     
   } completion:^(BOOL finished) {
     
     // We're timing how long a user is spending in each session. To do so, open a times session with
     // the method below. The method automatically closes any previously opened session so don't worry
     // about terminating the session
     [[AnalyticsManager shared] openTimedSessionForContentType:contentType];
     
     // the newsPath variable should really be deprecated. It's only use right now is if a user is loading an individual
     // Program page (ScreenContentTypeProgramPage). In that scenario, newsPath will represent the title of the program
     // the user is attempting to load. Supporting a method parameter for this one use isn't ideal.
     switch (contentType) {
       
         
       
       case ScreenContentTypeProgramPage:
         if ( [self.newsPath isEqualToString:@""] ) {
           [[NetworkManager shared] fetchContentForMasterProgramsList:self];
         } else {
           [self wipePreviousContent];
           [self displayProgramPage:nil target:self.newsPath];
         }
         break;
       case ScreenContentTypeSnapshotPage:
         [[NetworkManager shared] fetchContentForSnapshotPage:self];
         [[AnalyticsManager shared] logEvent: @"menu_select_editions" withParameters:@{}];
         break;
       case ScreenContentTypeCompositePage:
         [self wipePreviousContent];
         [self displaySimpleContent:@{}];
         [self finishTransition];
         [[AnalyticsManager shared] logEvent: @"menu_select_news" withParameters:@{}];
         break;
       case ScreenContentTypeEventsPage:
         [[NetworkManager shared] fetchContentForEventsPage:@""
                                                    display:self];
         break;
       case ScreenContentTypeProfilePage:
         [[NetworkManager shared] fetchContentForUserProfile:self];
         break;
       case ScreenContentTypeProgramAZPage:
         [[NetworkManager shared] fetchContentForProgramAZPage:self];
         [[AnalyticsManager shared] logEvent: @"menu_select_programs" withParameters:@{}];
         break;
       case ScreenContentTypeVideoPhotoPage:
         [[NetworkManager shared] fetchContentForVideoPhotoPage:self];
         [[AnalyticsManager shared] logEvent: @"menu_select_videophoto" withParameters:@{}];
         break;
         
      // The following two content types don't need any network calls so just present them
       case ScreenContentTypeFeedback:
         [self wipePreviousContent];
         [self displayFeedbackPage];
         [self finishTransition];
         break;
       case ScreenContentTypeOnboarding:
         [self wipePreviousContent];
         [self displayOnboardingPage];
         [self finishTransition];
         break;
      
      // Old content types we don't use anymore
         case ScreenContentTypeDynamicPage:
         case ScreenContentTypeNewsPage:
       default:
         break;
     }
     
   }];
  
}

/**************************************************************************************************
 -- Developer Note --
 handleDrawerCommand is another dispatching system that I was never happy with. The drawer is built dynamically
 from a flat json file (see faketopicschema.json in the resource bundle). The drawer's contents were programmed
 with the idea that they were going to be controllable from outside the app, and json is a good data storage in case
 the contents were ever going to need to be updated externally. To date, the app has not needed to pull the drawer schema
 from anywhere except the faketopicschema.json, but the idea is that the contents of that file can be fetched from
 somewhere else and easily dropped into the drawer. The problem is is if you'll look at how this method works, it
 is too tightly coupled with the hard contents of faketopicschema, i.e. the method searches for hits on values like
 "The Short List" or "Photo & Video". I've always wanted to redo this method such that the drawer understands
 the drawerCode independent of hard values.
 */
- (void)handleDrawerCommand:(NSString *)drawerCode {
  
  
  NSArray *tokens = [drawerCode componentsSeparatedByString:@"|"];
  if ( [tokens count] < 2 ) {
    return;
  }
  
  NSString *sectionKey = [NSString stringWithFormat:@"section%@",[tokens objectAtIndex:0]];
  NSDictionary *schema = [[[Utilities del] globalDrawer] schema];
  NSDictionary *sectionBlock = [schema objectForKey:sectionKey];
  NSArray *content = [sectionBlock objectForKey:@"content"];
  NSInteger item = [[tokens objectAtIndex:1] intValue];
  
  NSString *contentKey = @"";
  if ( item == [content count] ) {
    contentKey = @"All Programs";
  } else if ( item == [content count]+1 ) {
    contentKey = @"All Programs";
  } else {
    contentKey = [content objectAtIndex:item];
  }
  if ( [[tokens objectAtIndex:0] intValue] == 0 ) {
    if ( [contentKey isEqualToString:@"News"] ) {
      [self primeUI:ScreenContentTypeCompositePage newsPath:@""];
    }
    if ( [contentKey isEqualToString:@"The Short List"] ) {
      [self primeUI:ScreenContentTypeSnapshotPage newsPath:@""];
    }
    if ( [contentKey isEqualToString:@"Photo & Video"] ) {
      [self primeUI:ScreenContentTypeVideoPhotoPage newsPath:@""];
    }
    if ( [contentKey isEqualToString:@"Live Events"] ) {
      [self primeUI:ScreenContentTypeEventsPage newsPath:@""];
    }
  } else if ( [[tokens objectAtIndex:0] intValue] == 1 ) {
    if ( [contentKey isEqualToString:@"All Programs"] ) {
      [self primeUI:ScreenContentTypeProgramAZPage newsPath:@""];
    } else {
      [self primeUI:ScreenContentTypeProgramPage newsPath:contentKey];
    }
  } else if ( [contentKey isEqualToString:@"Feedback"] ) {
    [self primeUI:ScreenContentTypeFeedback newsPath:@""];
  }

  // Check promo
  NSString *promo = [[ContentManager shared].settings promotionalContent];
  if ( [Utilities pureNil:promo] ) {
    return;
  }
  
  NSDictionary *pDict = [promo JSONValue];
  NSString *ct = [pDict objectForKey:@"contentTitle"];
  if ( [ct isEqualToString:contentKey] ) {
    NSString *url = [pDict objectForKey:@"contentUrl"];
    [[[Utilities del] masterRootController] puntToSafariWithURL:url];
  }

}

#pragma mark - Helpers
- (SCPRNewsPageContainerController*)containerFor:(id<ContentContainer>)page hideStrip:(BOOL)hideStrip {
  SCPRNewsPageContainerController *container = [[SCPRNewsPageContainerController alloc]
                                                initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPRNewsPageContainerController"]
                                                bundle:nil];
  // Couple these.
  //page.parentContainer = container;
  container.child = page;
  
  UIViewController *uvc = (UIViewController*)page;
  
  [container loadView];
  
  CGFloat adjust = hideStrip ? 0.0 : container.grayStrip.frame.size.height;
  uvc.view.frame = CGRectMake(uvc.view.frame.origin.x,
                              uvc.view.frame.origin.y+adjust,
                              uvc.view.frame.size.width,
                              uvc.view.frame.size.height);
  
  container.contentScroller.contentSize = CGSizeMake(page.view.frame.size.width,
                                                     page.view.frame.size.height+60.0);
  [container.contentScroller addSubview:page.view];
  return container;
}

- (void)viewWillLayoutSubviews {

}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
  return YES;
}

#pragma mark - Content layouts
/*********************************************************************************/
// -- Developer Note --
//
// The small cutter class I used primarily as a utility to output square, small cuts of the large program splash images used in the program AZ page.
// It has no functional purpose at runtime so the call to this function is disabled, however use it when a program's splash image changes. You could do the
// cutting with Photoshop or similar but I found this is just as effective. Run this function in the simulator and then check your images directory in
// the .app package created in the iOS Simulator runtime directory to pull the new images. Unfortunately the titles will be sha1 hashes so you'll have to go
// through them to see which are the relevant images, but this IMO is less intrusive than doing the proper cut yourself in Photoshop
- (void)processProgramImagesInBackground {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
    self.smallCutter = [[SCPRSmallCutViewController alloc]
                        initWithNibName:[[DesignManager shared]
                                         xibForPlatformWithName:@"SCPRSmallCutViewController"]
                        bundle:nil];
    [[NetworkManager shared] fetchContentForProgramAZPage:self.smallCutter];
    
    
  });
}

/********************************************************************************/
// -- Developer Note --
// This method is meant to build the program pages out based on the user's favorites and then keep this collection in
// memory for performance reasons
//
- (void)buildProgramPages:(BOOL)favoritesOnly {

  
  if ( favoritesOnly ) {
    if ( [Utilities pureNil:[[ContentManager shared].settings favoriteProgramsAsJson]] ) {
      return;
    }
  }
  
  if ( self.programPages ) {
    for ( SCPRProgramPageViewController *p in self.programPages.programVector ) {
      [p.view removeFromSuperview];
    }
    [self.programPages.programVector removeAllObjects];
  }
  
  self.programPages = [[SCPRProgramNavigatorViewController alloc]
                       initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRProgramNavigatorViewController"]
                       bundle:nil];
  
  NSArray *programs = [[ContentManager shared] favoritedProgramsList];
  self.programPages.view.frame = CGRectMake(0.0,0.0,self.programPages.view.frame.size.width,
                                            self.programPages.view.frame.size.height);
  self.programPages.programVector = [[NSMutableArray alloc] init];
  CGSize s = CGSizeMake([programs count]*self.programPages.programScroller.frame.size.width,
                                                             self.programPages.programScroller.frame.size.height);
  self.programPages.programScroller.contentSize = s;
  for ( unsigned i = 0; i < [programs count]; i++ ) {
    NSDictionary *program = [programs objectAtIndex:i];
    SCPRProgramPageViewController *ppvc = [[SCPRProgramPageViewController alloc]
                                           initWithNibName:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramPageViewController"]
                                           bundle:nil];
    ppvc.view.frame = CGRectMake(i*ppvc.view.frame.size.width,0.0,
                                 ppvc.view.frame.size.width,
                                 ppvc.view.frame.size.height);
    
    
    
    [self.programPages.programScroller addSubview:ppvc.view];
    ppvc.programObject = [[ContentManager shared] maximizedProgramForMinimized:program];
    
    
    [self.programPages.programVector addObject:ppvc];
  }
  
}

- (void)buildCompleteProgramList {
  self.completeProgramPages = [[SCPRProgramNavigatorViewController alloc]
                       initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRProgramNavigatorViewController"]
                       bundle:nil];
  
  NSArray *programs = [[ContentManager shared] sortedProgramList];
  self.completeProgramPages.view.frame = CGRectMake(0.0,0.0,self.completeProgramPages.view.frame.size.width,
                                            self.completeProgramPages.view.frame.size.height);
  self.completeProgramPages.programVector = [[NSMutableArray alloc] init];
  self.completeProgramPages.programScroller.contentSize = CGSizeMake([programs count]*self.completeProgramPages.programScroller.frame.size.width,
                                                             self.completeProgramPages.programScroller.frame.size.height);
  for ( unsigned i = 0; i < [programs count]; i++ ) {
    NSDictionary *program = [programs objectAtIndex:i];
    SCPRProgramPageViewController *ppvc = [[SCPRProgramPageViewController alloc]
                                           initWithNibName:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramPageViewController"]
                                           bundle:nil];
    ppvc.view.frame = CGRectMake(i*ppvc.view.frame.size.width,0.0,
                                 ppvc.view.frame.size.width,
                                 ppvc.view.frame.size.height);
    
    [self.completeProgramPages.programScroller addSubview:ppvc.view];
    ppvc.programObject = [[ContentManager shared] maximizedProgramForMinimized:program];

    
    [self.completeProgramPages.programVector addObject:ppvc];
  }
}

- (void)buildNewsPages:(NSMutableArray *)contentObjects {
  
  self.numberOfStoriesPerPage = [Utilities isIpad] ? 3 : 2;
  if ( self.padThinContent ) {
    self.articlesInCategories = [self categoryHashForArticleSet:self.mediaContent];
  }
  self.pagesHashedByTopic = [[NSMutableDictionary alloc] init];
  
  NSArray *schema = [self.articlesInCategories objectForKey:@"schema"];
  self.mainPageScroller.contentSize = CGSizeMake(self.mainPageScroller.frame.size.width*[schema count],
                                                 self.mainPageScroller.frame.size.height);
  self.topicSelector.frame = CGRectMake(0.0,[[Utilities del] globalTitleBar].view.frame.size.height,self.topicSelector.frame.size.width,
                                        self.topicSelector.frame.size.height);
  [self.view addSubview:self.topicSelector];
  
  for ( unsigned i = 0; i < [schema count]; i++ ) {
    NSString *topic = [schema objectAtIndex:i];
    NSMutableArray *topicObjects = [self.articlesInCategories objectForKey:topic];
    NSInteger count = ceilf([topicObjects count]/(self.numberOfStoriesPerPage*1.0));
    
    SCPRNewsPageContainerController *container = [[SCPRNewsPageContainerController alloc]
                                                   initWithNibName:[[DesignManager shared]
                                                                    xibForPlatformWithName:@"SCPRNewsPageContainerController"]
                                                   bundle:nil];
    

    container.pageIndex = i;
    container.view.frame = CGRectMake(0.0,0.0,
                                      container.view.frame.size.width,
                                      self.mainPageScroller.frame.size.height);
    
    container.contentScroller.contentSize = CGSizeMake(self.mainPageScroller.frame.size.width,
                                                       self.mainPageScroller.frame.size.height*count);
    
    container.observableScroller = self.mainPageScroller;
    container.pageTitleLabel.alpha = 0.0;
    container.topicSlug = topic;
    container.newsPages = [[NSMutableArray alloc] init];
    container.originalQuantity = [topicObjects count];
    container.contentDelegate = self;
    for ( unsigned j = 0; j < count; j++ ) {
      SCPRNewsPageViewController *newsPage = [[SCPRNewsPageViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                  xibit:@"SCPRNewsPageViewController"
                                                                                                  style:(j % 2)]
                                                                                          bundle:nil];
      newsPage.view.frame = CGRectMake(0.0,0.0,
                                       newsPage.view.frame.size.width,
                                       newsPage.view.frame.size.height);
      newsPage.contentDelegate = self;
      newsPage.pageIndex = j;
      newsPage.topicTitleCode = [NSString stringWithFormat:@"Home-%d",j];
      newsPage.templateType = (j % 2);
      newsPage.view.alpha = 0.0;
      newsPage.topicSlug = topic;
      newsPage.parentContainer = container;
      
      CGRect containerFrame = CGRectMake(0.0,j*newsPage.view.frame.size.height,
                                         container.view.frame.size.width,
                                         self.mainPageScroller.frame.size.height);
      
      
      newsPage.view.frame = containerFrame;
      
      [container.contentScroller addSubview:newsPage.view];
      
   
      [newsPage activatePage];
      
      [container.newsPages addObject:newsPage];
    }
    
    UINavigationController *unc = [[UINavigationController alloc] initWithRootViewController:container];
    unc.navigationBar.hidden = YES;
    unc.view.frame = CGRectMake(container.view.frame.size.width*i,
                                0.0,
                                container.view.frame.size.width,
                                container.view.frame.size.height);
    container.designatedNav = unc;
    [self.mainPageScroller addSubview:unc.view];
    [self.contentVector addObject:unc];
    [self.contentVector addObject:container];
    [self.pagesHashedByTopic setObject:container
                                forKey:topic];
  }
  
  if ( self.padThinContent ) {
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      [self padContentGaps];
   // });
  }
  
}

- (void)padContentGaps {
  
  self.backgroundFetchQueue = [[NSMutableArray alloc] init];
  NSDictionary *groupHash = [self categoryMap];
  for ( NSString *key in [groupHash allKeys] ) {
 
    NSMutableArray *contentByTopic = [self mediaContentForTopic:key];
    if ( [contentByTopic count] < kMinimumArticleQuantity ) {
      NSArray *atoms = [groupHash objectForKey:key];
      int c = 0;
      NSString *query = @"";
      for ( NSString *atom in atoms ) {
        if ( c > 0 ) {
          query = [query stringByAppendingString:@","];
        }
        c++;
        query = [query stringByAppendingString:atom];
      }
      NSInteger needed = kMinimumArticleQuantity - [contentByTopic count];
      //NSLog(@"Need %d for %@",needed,key);
      NSDictionary *params = @{ @"quantity" : [NSNumber numberWithInt:needed] };
      
      [self.backgroundFetchQueue addObject:@{ @"query" : query, @"flags" : params }];

  
    }
  }
  
  [self workOnBackgroundFetch];
  
}

- (void)workOnBackgroundFetch {
  
  if ( [self.backgroundFetchQueue count] == 0 ) {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"content_load_finished"
                                                        object:nil];
    return;
  }
    
  
  NSDictionary *first = [self.backgroundFetchQueue objectAtIndex:0];
  [self.backgroundFetchQueue removeObjectAtIndex:0];
  
  [[NetworkManager shared] fetchContentForTopic:[first objectForKey:@"query"]
                                        display:self
                                          flags:[first objectForKey:@"flags"]];
}

- (NSDictionary*)categoryMap {

  NSDictionary *groupHash = (NSDictionary*)[Utilities loadJson:@"category_groups"];
  return groupHash;
}

- (void)displaySnapshot:(NSMutableArray *)contentObjects edition:(SnapshotEdition)edition {
  

  
  SCPREditionMineralViewController *mineral = [[SCPREditionMineralViewController alloc]
                                               initWithNibName:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPREditionMineralViewController"]
                                               bundle:nil];
  
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mineral];
  
  
  CGFloat offset = [Utilities isIOS7] ? 0.0 : -20.0;

  CGRect r = CGRectMake(0.0, offset, mineral.view.bounds.size.width,
                              mineral.view.bounds.size.height)/*[[DesignManager shared] orientedZeroFrameFor:mineral]*/;
  nav.view.frame = r;
  
  [self.contentVector addObject:mineral];
  [self.mainPageScroller addSubview:nav.view];
  nav.navigationBarHidden = YES;
  
  self.pushedContent = nav;
  
  [[ContentManager shared] pushToResizeVector:mineral];
  [mineral setupWithEditions:[NSArray arrayWithArray:contentObjects]];
  
  
}

- (void)displayWebContent:(NSMutableArray *)contentObjects {

}


- (void)displayProgramAZPage:(NSMutableArray *)contentObjects {
  

  
  
  [[[Utilities del] globalTitleBar] morph:BarTypeProgramAtoZ container:nil];
  
  SCPRProgramAZViewController *ppvc = [[SCPRProgramAZViewController alloc]
                                         initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRProgramAZViewController"]
                                         bundle:nil];
  
  ppvc.programsMasterList = contentObjects;
  

  
  CGRect r = CGRectMake(0.0,0.0,
                                   ppvc.view.frame.size.width,
                                   ppvc.view.frame.size.height);
  ppvc.view.frame = r;
  
  CGRect sf = ppvc.programPickerView.frame;
  
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ppvc];

  ppvc.navigationController.navigationBarHidden = YES;
  
  CGRect containerFrame = CGRectMake(0.0,-20.0,
                                     ppvc.view.frame.size.width,
                                     self.mainPageScroller.frame.size.height);
  nav.view.frame = containerFrame;
  
  [[ContentManager shared] pushToResizeVector:ppvc];
  
  [self.mainPageScroller addSubview:nav.view];
  [self.contentVector addObject:ppvc];

  sf = ppvc.programPickerView.frame;
  
  self.pushedContent = nav;

  
  
  
}

- (void)displayProgramPage:(NSMutableArray *)contentObjects target:(NSString *)show {
  
  
  
  if ( [show isEqualToString:@""] ) {
    [self buildCompleteProgramList];
    
    self.completeProgramPages.view.frame = CGRectMake(0.0,0.0,self.completeProgramPages.view.frame.size.width,
                                              self.completeProgramPages.view.frame.size.height);
    
    
    [self.mainPageScroller addSubview:self.completeProgramPages.view];
    
    
    [self.completeProgramPages focusShowWithIndex:0];
    [self finishTransition];
    
    return;
  }
  
  //if ( !self.programPages ) {
    [self buildProgramPages:YES];
  //}
  
  NSArray *programs = [[ContentManager shared] favoritedProgramsList];
  NSInteger index = 0;
  for ( unsigned i = 0; i < [programs count]; i++ ) {
    NSDictionary *d = [programs objectAtIndex:i];
    if ( [show isEqualToString:[d objectForKey:@"title"]] ) {
      index = i;
      break;
    }
  }
  
  [[ContentManager shared] pushToResizeVector:self.programPages];
  
  self.programPages.view.frame = CGRectMake(0.0,0.0,self.programPages.view.frame.size.width,
                                            self.programPages.view.frame.size.height);
  
  
  [self.mainPageScroller addSubview:self.programPages.view];
  

  [self.programPages focusShowWithIndex:index];
  [self finishTransition];
}

- (void)displaySimpleContent:(NSDictionary *)contentObjects {
  
  [[QueueManager shared] setStories:contentObjects];
  if ( self.silentlyFetchingNews ) {
    
    [[ContentManager shared] processStories];
    return;
  }

  
  SCPRDeluxeNewsViewController *vpvc = [[SCPRDeluxeNewsViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRDeluxeNewsViewController"]
                                        bundle:nil];

  vpvc.rawArticleHash = [contentObjects mutableCopy];
  vpvc.contentType = ScreenContentTypeCompositePage;
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vpvc];
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  [[ContentManager shared] pushToResizeVector:vpvc];
  
  CGFloat widthToUse = vpvc.view.bounds.size.width;
  CGFloat heightToUse = vpvc.view.bounds.size.height;
  

  CGFloat adjust = 0.0;
  CGFloat yAdjust = 0.0;
  if ( [Utilities isIOS7] ) {
    adjust = 20.0;
    yAdjust = 0.0;
  } else {
    adjust = -20.0;
    yAdjust = -20.0;
  }
    
  nav.view.frame = CGRectMake(0.0,yAdjust,
                              widthToUse,
                              heightToUse-adjust);
  
  vpvc.navigationController.navigationBarHidden = YES;
  
  self.mainPageScroller.contentSize = CGSizeMake(vpvc.view.frame.size.width,
                                                 vpvc.view.frame.size.height);
  
  [self.contentVector addObject:vpvc];
  
  [[ContentManager shared] setCurrentNewsPage:1];
  [vpvc fetchContent:nil];
  
  
}

- (void)displayEventsPage:(NSMutableDictionary *)contentObjects {
  
  NSArray *allPosts = [contentObjects objectForKey:@"all_posts"];
  SCPRDeluxeNewsViewController *vpvc = [[SCPRDeluxeNewsViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRDeluxeNewsViewController"]
                                        bundle:nil];
  vpvc.contentType = ScreenContentTypeEventsPage;
  vpvc.posts = allPosts;
  vpvc.bigHash = [contentObjects objectForKey:@"big_posts"];
  
  vpvc.view.frame = vpvc.view.frame;
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vpvc];
  
  CGFloat widthToUse = vpvc.view.bounds.size.width;
  CGFloat heightToUse = vpvc.view.bounds.size.height;
  
  
  CGFloat adjust = 0.0;
  CGFloat yAdjust = 0.0;
  if ( [Utilities isIOS7] ) {
    adjust = 20.0;
    yAdjust = 0.0;
  } else {
    adjust = -20.0;
    yAdjust = -20.0;
  }
  
  nav.view.frame = CGRectMake(0.0,yAdjust,
                              widthToUse,
                              heightToUse-adjust);
  
  vpvc.navigationController.navigationBarHidden = YES;
  
  self.mainPageScroller.contentSize = CGSizeMake(vpvc.view.frame.size.width,
                                                 vpvc.view.frame.size.height);
  
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  
  
  vpvc.navigationController.navigationBarHidden = YES;
  
  [[ContentManager shared] pushToResizeVector:vpvc];
  [self.contentVector addObject:vpvc];
  
  
}

- (void)displayUserProfilePage:(NSMutableArray *)contentObjects {
  
  SCPRProfileViewController *profile = [[SCPRProfileViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRProfileViewController"]
                                        bundle:nil];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:profile];
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  nav.view.frame = CGRectMake(0.0,0.0,
                              profile.view.frame.size.width,
                              profile.view.frame.size.height);
  
  profile.navigationController.navigationBarHidden = YES;
  
  [[ContentManager shared] pushToResizeVector:profile];
  
  [self.contentVector addObject:profile];
  
  self.mediaContent = contentObjects;
  [profile sourceWithListenedSegments:contentObjects];
}

- (void)displayVideoPhotoPage:(NSDictionary *)contentObjects {
  
  NSArray *allPosts = [contentObjects objectForKey:@"all_posts"];
  SCPRDeluxeNewsViewController *vpvc = [[SCPRDeluxeNewsViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRDeluxeNewsViewController"]
                                        bundle:nil];
  vpvc.contentType = ScreenContentTypeVideoPhotoPage;
  vpvc.posts = allPosts;
  vpvc.bigHash = [contentObjects objectForKey:@"big_posts"];
  
  vpvc.view.frame = vpvc.view.frame;
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vpvc];
  
  CGFloat widthToUse = vpvc.view.bounds.size.width;
  CGFloat heightToUse = vpvc.view.bounds.size.height;
  
  
  CGFloat adjust = 0.0;
  CGFloat yAdjust = 0.0;
  if ( [Utilities isIOS7] ) {
    adjust = 20.0;
    yAdjust = 0.0;
  } else {
    adjust = -20.0;
    yAdjust = -20.0;
  }
  
  nav.view.frame = CGRectMake(0.0,yAdjust,
                              widthToUse,
                              heightToUse-adjust);
  
  vpvc.navigationController.navigationBarHidden = YES;
  
  self.mainPageScroller.contentSize = CGSizeMake(vpvc.view.frame.size.width,
                                                 vpvc.view.frame.size.height);
  
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];

  
  vpvc.navigationController.navigationBarHidden = YES;
  
  [[ContentManager shared] pushToResizeVector:vpvc];
  [self.contentVector addObject:vpvc];
  

}

- (void)displayUnderConstructionPage:(NSString *)pageTitle {
  SCPRUnderConstructionViewController *vpvc = [[SCPRUnderConstructionViewController alloc]
                                        initWithNibName:[[DesignManager shared]
                                                         xibForPlatformWithName:@"SCPRUnderConstructionViewController"]
                                        bundle:nil];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vpvc];
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  nav.view.frame = CGRectMake(0.0,0.0,
                              vpvc.view.frame.size.width,
                              vpvc.view.frame.size.height);
  
  vpvc.navigationController.navigationBarHidden = YES;
  
  [self.contentVector addObject:vpvc];
  

}

- (void)displayFeedbackPage {
  SCPRFeedbackViewController *fbvc = [[SCPRFeedbackViewController alloc]
                                      initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRFeedbackViewController"]
                                      bundle:nil];

  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:fbvc];
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  nav.view.frame = CGRectMake(0.0,0.0,
                              fbvc.view.frame.size.width,
                              fbvc.view.frame.size.height);
  
  fbvc.navigationController.navigationBarHidden = YES;
  
  [self.contentVector addObject:fbvc];
}

- (void)displayOnboardingPage {
  SCPROnboardingFlowViewController *flow = [[SCPROnboardingFlowViewController alloc]
                                            initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPROnboardingFlowViewController"]
                                            bundle:nil];
  flow.firstRun = self.onboardingFirstTime;
  
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flow];
  self.pushedContent = nav;
  [self.mainPageScroller addSubview:nav.view];
  nav.view.frame = CGRectMake(0.0,0.0,
                              self.mainPageScroller.frame.size.width,
                              self.mainPageScroller.frame.size.height);
  
  flow.navigationController.navigationBarHidden = YES;
  
  [[ContentManager shared] pushToResizeVector:flow];
  [self.contentVector addObject:flow];
}

#pragma mark - CurrentVersion
- (void)currentVersionCallback:(PFObject *)cvDetails {
  
  NSString *appVersion = [cvDetails objectForKey:@"appVersion"];
  NSString *thisVersion = [Utilities prettyShortVersion];
  NSString *greater = [Utilities higherVersionBetween:thisVersion thatVersion:appVersion];
  if ( ![greater isEqualToString:thisVersion] ) {
    
    NSString *message = @"There is a new version of the KPCC iPad app available. Tap here to proceed to the download area.";
    BOOL reinstall = [[cvDetails objectForKey:@"reinstallRequired"] boolValue];
    if ( reinstall ) {
      message = [message stringByAppendingString:@" Please remove this current installation before downloading."];
    }
    
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root showBreakingNewsWithMessage:message action:^{
      NSURL *url = [NSURL URLWithString:@"http://bit.ly/ipadbetainvite?elq=5c408852c5ec49b18166d60a446f6932&elqCampaignId="];
      [[UIApplication sharedApplication] openURL:url];
    }];
  } else {
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root hideBreakingNews];
  }
  
}

#pragma mark - ContentProcessor
- (NSMutableArray*)mediaContentForTopic:(NSString *)topic {
  if ( [self.articlesInCategories objectForKey:topic] ) {
    return [self.articlesInCategories objectForKey:topic];
  }
  
  NSString *masterKey = [self masterKeyForTopic:topic];
  return [self.articlesInCategories objectForKey:masterKey];
}

- (NSString*)masterKeyForTopic:(NSString *)topic {
  NSMutableDictionary *reverseHash = [[Utilities reverseHash:[self categoryMap]] mutableCopy];
  
  if ( [topic rangeOfString:@","].location != NSNotFound ) {
    NSArray *tokens = [topic componentsSeparatedByString:@","];
    topic = [tokens objectAtIndex:0];
  }
  
  NSString *masterKey = [reverseHash objectForKey:topic];
  return masterKey;
}

- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  
  self.mediaContent = [NSMutableArray arrayWithArray:content];
  if ( self.silentlyFetchingNews ) {
    self.silentlyFetchingNews = NO;
    return;
  }
  
  [self wipePreviousContent];
  
  switch (self.currentNewsType) {
    case ScreenContentTypeNewsPage:
      self.mediaContent = [self stripBadContent:self.mediaContent];
      [self buildNewsPages:self.mediaContent];
      break;
    case ScreenContentTypeDynamicPage:
      [self displayWebContent:self.mediaContent];
      break;
    case ScreenContentTypeProgramPage:
      if ( [flags objectForKey:@"master"] ) {
        [self displayProgramPage:self.mediaContent target:@""];
      } else {
        [self displayProgramPage:self.mediaContent target:[flags objectForKey:@"target"]];
      }
      break;
    case ScreenContentTypeSnapshotPage:
      [self displaySnapshot:self.mediaContent
                    edition:[Utilities snapshotEditionForTimeOfDay]];
      break;
    case ScreenContentTypeEventsPage:
      [self displayUnderConstructionPage:@""];
      break;
    case ScreenContentTypeProfilePage:
      [self displayUserProfilePage:self.mediaContent];
      break;
    case ScreenContentTypeProgramAZPage:
      [[ContentManager shared] filterPrograms:self.mediaContent];
      if ( ![Utilities pureNil:[[ContentManager shared] masterProgramList]] ) {
        [self displayProgramAZPage:self.mediaContent];
      }
      break;
    case ScreenContentTypeVideoPhotoPage:

      break;
    case ScreenContentTypeUnderConstruction:
      [self displayUnderConstructionPage:@""];
      break;
    case ScreenContentTypeCompositePage:
      break;
    default:
      
      break;
  }
  
  
  [self finishTransition];
}

- (void)handleVideoPhoto:(NSDictionary *)content {
  [self wipePreviousContent];
  [self displayVideoPhotoPage:content];
  [self finishTransition];
}

- (void)handleEvents:(NSDictionary *)content {
  [self wipePreviousContent];
  [self displayEventsPage:[content mutableCopy]];
  [self finishTransition];
}

- (void)handleCompositeNews:(NSDictionary *)content {
  
  if ( !self.silentlyFetchingNews ) {
    [self wipePreviousContent];
  }
  [self displaySimpleContent:content];
  if ( !self.silentlyFetchingNews ) {
    [self finishTransition];
  } else {
    self.silentlyFetchingNews = NO;
  }
  
}

- (void)finishTransition {
  [[Utilities del] closeDrawer];
  [[Utilities del] setLaunchFinished:YES];
  
  [UIView animateWithDuration:0.25 animations:^{
    [[[Utilities del] masterRootController] uncloak];
    [[Utilities del].globalPlayer.view setAlpha:1.0];
  } completion:^(BOOL finished) {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ui_primed"
                                                        object:nil];
    
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    if ( [root.breakingNewsOverlay showing] ) {
      [root.view bringSubviewToFront:root.breakingNewsOverlay.view];
    }
    
    [self.view bringSubviewToFront:root.globalGradient];
    [root.view bringSubviewToFront:root.cloakView];
    
#ifndef FAKE_TOUR
    if ( ![[ContentManager shared].settings onboardingShown] ) {
#endif
      [[[Utilities del] masterRootController] showIntro];
#ifndef FAKE_TOUR
    }
#endif

#ifdef FAKE_PUSH_NOTIFICATION
    NSDictionary *userInfo = @{ @"aps" : @{ @"alert" : @"THIS IS A TEST" },
                                @"alertId" : @"560" };
    [[ContentManager shared] displayPushMessageWithPayload:userInfo];
#endif
    
    if ( [[ContentManager shared] pendingNotification] ) {
 
      NSMutableDictionary *note = [[ContentManager shared] pendingNotification];
      NSDictionary *aps = [note objectForKey:@"aps"];
      NSString *alert = [aps objectForKey:@"alert"];
      
      NSString *happeningCap = [[@"HAPPENING NOW" lowercaseString] capitalizedString];
      NSString *allcaps = [happeningCap uppercaseString];
      NSString *allLow = [happeningCap lowercaseString];
      
      if ( [alert rangeOfString:happeningCap].location == NSNotFound &&
          [alert rangeOfString:allcaps].location == NSNotFound &&
          [alert rangeOfString:allLow].location == NSNotFound ) {
        [[ContentManager shared] convertBreakingNewsToArticle:[note objectForKey:@"alertId"]];
        [[ContentManager shared] setPendingNotification:nil];
      } else {
        [[ContentManager shared] setPendingNotification:nil];
        [self primeUI:ScreenContentTypeEventsPage
             newsPath:@""];
      }
      
    }
    
    if ( ![[Utilities del] firstLaunchAndDisplayFinished] ) {
      // Write to parse after loading has completed
      [[ContentManager shared] writeSettings];
      [[Utilities del] setFirstLaunchAndDisplayFinished:YES];
      //[[NetworkManager shared] fetchEditionsInBackground];
      
      if ( [[Utilities del] drawerIsDirty] ) {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
          
          [[[Utilities del] globalDrawer] respin];
          
        //});
      }
    }
    
  }];
  

}

- (void)handleAdditionalContent:(NSArray *)content forTopic:(NSString *)topic {

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
  
    NSMutableArray *media = [self mediaContentForTopic:topic];
    
    NSMutableArray *sum = [[NSMutableArray alloc] initWithArray:media];
    for ( NSDictionary *article in content ) {
      NSString *candidateHash = [Utilities sha1:[article objectForKey:@"permalink"]];
      
      BOOL unique = YES;
      for ( NSDictionary *incumbent in media ) {
        NSString *incumbentHash = [Utilities sha1:[incumbent objectForKey:@"permalink"]];
        if ( [incumbentHash isEqualToString:candidateHash] ) {
          //NSLog(@"Skipping duplicate...");
          unique = NO;
          break;
        }
      }
      
      if ( unique ) {
        [sum addObject:article];
      }
      
    }
    
    sum = [self stripBadContent:sum];
    sum = [[sum sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      
      NSDictionary *d1 = (NSDictionary*)obj1;
      NSDictionary *d2 = (NSDictionary*)obj2;
      
      NSString *rfc1 = [d1 objectForKey:@"published_at"];
      NSString *rfc2 = [d2 objectForKey:@"published_at"];
      
      NSDate *date1 = [Utilities dateFromRFCString:rfc1];
      NSDate *date2 = [Utilities dateFromRFCString:rfc2];
      
      return (NSComparisonResult)[date2 compare:date1];
      
    }] mutableCopy];
    
    [self.articlesInCategories setObject:sum forKey:[self masterKeyForTopic:topic]];

    

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.currentContainer appendContentForTopic:[self masterKeyForTopic:topic]];
    });
    
    
  });
  
}

- (NSMutableArray*)stripBadContent:(NSMutableArray*)dirtyContent {
  NSMutableArray *stripped = [[NSMutableArray alloc] init];
  for ( id d in dirtyContent ) {
    
    NSDictionary *asDictionary = nil;
    if ( [d isKindOfClass:[NSDictionary class]] ) {
      asDictionary = (NSDictionary*)d;
    } else {
      NSLog(@"Not a dictionary");
      continue;
    }
    NSDictionary *image = [Utilities imageObjectFromBlob:d
                                                 quality:AssetQualityFull];
    if ( [Utilities pureNil:image] ) {
      NSLog(@"Stripping content %@",[asDictionary objectForKey:@"permalink"]);
      continue;
    }
    
    [stripped addObject:d];
  }

  return stripped;
}

- (NSMutableDictionary*)categoryHashForArticleSet:(NSArray *)articles {
  
  NSMutableDictionary *hash = [[NSMutableDictionary alloc] init];
  for ( NSDictionary *article in articles ) {
    
    NSDictionary *category = [article objectForKey:@"category"];
    if ( category ) {
      NSMutableArray *catVector = [hash objectForKey:[category objectForKey:@"slug"]];
      if ( !catVector ) {
        catVector = [[NSMutableArray alloc] init];
        [hash setObject:catVector forKey:[category objectForKey:@"slug"]];
      }
      [catVector addObject:article];
    }
    
  }
  
  NSDictionary *groupHash = [self categoryMap];
  
  NSMutableDictionary *cookedHash = [[NSMutableDictionary alloc] init];
  for ( NSString *key in [groupHash allKeys] ) {
    NSArray *groupings = [groupHash objectForKey:key];
    NSMutableArray *aggregateForCategory = [[NSMutableArray alloc] init];
    for ( NSString *cat in groupings ) {
      NSMutableArray *catVector = [hash objectForKey:cat];
      if ( catVector ) {
        [aggregateForCategory addObjectsFromArray:catVector];
      }
    }
    [cookedHash setObject:aggregateForCategory
                   forKey:key];
    //NSLog(@"%d article(s) for %@",aggregateForCategory.count,key);
  }
  
  [cookedHash setObject:@[ @"us-world", @"health-ed", @"local", @"arts-culture" ]
                 forKey:@"schema"];
  
  return cookedHash;
}

- (void)globalInit {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(revive)
                                               name:@"wake_up_ui"
                                             object:nil];
  
  if ( [[Utilities del] appCloaked] ) {
    return;
  }
  
  // The white cloak
  

  
  
  NSString *titleBarXIB = @"SCPRTitlebarViewController";
#ifdef TESTING_SPECIAL_UI
  titleBarXIB = @"SCPRSpecialTitlebarViewController";
#endif
  
  self.titleBarController = [[SCPRTitlebarViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:titleBarXIB]
                                                                         bundle:nil];
  if ( [Utilities isIOS7] ) {
    self.titleBarController.view.frame = CGRectMake(self.titleBarController.view.frame.origin.x,
                                                    self.titleBarController.view.frame.origin.y+20.0,
                                                    self.titleBarController.view.frame.size.width,
                                                    self.titleBarController.view.frame.size.height);
  }
  
  self.view.backgroundColor = [UIColor blackColor];
  
  [[[Utilities del] globalTitleBar] morph:BarTypeDrawer container:nil];
  
  [[DesignManager shared] treatButton:self.playLocalButton
                            withStyle:ButtonStyleKPCCBlue];
  [[DesignManager shared] treatButton:self.showOrHidePlayerButton
                            withStyle:ButtonStyleKPCCBlue];
  
  self.mainPageScroller.pagingEnabled = YES;  
  self.showOrHidePlayerButton.alpha = 0.0;
  
  if ( [Utilities isIOS7] ) {
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_gradient_7.png"]];
    self.globalGradient.image = [UIImage imageNamed:@"top_gradient_7.png"];
    self.globalGradient.frame = CGRectMake(0.0,0.0,self.globalGradient.frame.size.width,
                                         iv.frame.size.height);
  }
  
  self.globalGradient.alpha = 0.0;
  
  [self.view addSubview:self.titleBarController.view];
  
#ifdef TESTING_SPECIAL_UI
  self.titleBarController.specialView.backgroundColor = [[DesignManager shared] slateColor:1.0];
  self.titleBarController.view.backgroundColor = [UIColor clearColor];
#endif
  


  
  [self.view bringSubviewToFront:self.titleBarController.view];
  
  

  
}




#ifdef DEBUG
- (void)loadListOfSegmentsFromQueue {
  Collection *queue = (Collection*)[[ContentManager shared] findModelByName:@"Science Station"
                                                                 andType:ModelTypeCollection];
  NSString *segmentString = @"";
  int counter = 0;
  if ( queue ) {
    NSSet *items = queue.segments;
    for ( Segment *segment in items ) {
      if ( counter > 0 ) {
        segmentString = [segmentString stringByAppendingString:@"\n"];
      }
      segmentString = [segmentString stringByAppendingString:segment.name];
      counter++;
    }
    
  }
  self.stationMapLabel.text = segmentString;
  
  NSSet *localShows = [[ContentManager shared] findSegmentsWithKeyword:@"local"];
  NSLog(@"Local Show count : %d",[localShows count]);
  

}
#endif

#pragma mark - UI / Controls
- (IBAction)switchToggled:(id)sender {
  NSInteger index = self.topicSelector.selectedSegmentIndex;
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.5];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [self.mainPageScroller setContentOffset:CGPointMake(index*self.mainPageScroller.frame.size.width,0.0)
                                 animated:NO];
  [UIView commitAnimations];
}

- (void)wipePreviousContent {
  [self.topicSelector removeFromSuperview];
  [[ContentManager shared] popFromResizeVector];
  
  
  [self.mainPageScroller setContentOffset:CGPointMake(0.0, 0.0)];
  
  @synchronized(self) {

    for ( UIView *v in [self.mainPageScroller subviews] ) {
      if ( v && (id) v != [NSNull null] ) {
        [v removeFromSuperview];
      }
    }
  
    self.mainPageScroller.contentSize = CGSizeMake(self.mainPageScroller.frame.size.width,
                                                 self.mainPageScroller.frame.size.height);
  
  
    for ( id prev in self.contentVector ) {
      [[NSNotificationCenter defaultCenter] removeObserver:prev];
      if ( [Utilities pureNil:prev] ) {
        continue;
      }
      if ( [prev respondsToSelector:@selector(unplug)] ) {
        [prev unplug];
      }
      
    }
    
    [self.contentVector removeAllObjects];
    self.currentContainer = nil;
    self.pushedContent = nil;
    
    [[ContentManager shared] sweepMemory];
    
  }
  
}

- (void)revive {
  
}

- (void)toggleReturnToLive:(BOOL)animated {

}

- (void)forceHideOfReturnToLive {
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.25];
  self.returnToLiveSeat.center = CGPointMake(self.view.center.x,0.0-self.returnToLiveSeat.frame.size.height/2.0-1.0);
  [UIView commitAnimations];
  
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

}

- (void)drawerOpened {
  self.mainPageScroller.userInteractionEnabled = NO;
  self.playerWidget.view.userInteractionEnabled = NO;
  self.drawerSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeDrawerBySwipe)];
  self.drawerSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
  
  
  [self.view addGestureRecognizer:self.drawerSwiper];
}

- (void)drawerClosed {
  self.mainPageScroller.userInteractionEnabled = YES;
  self.playerWidget.view.userInteractionEnabled = YES;
  [self.view removeGestureRecognizer:self.drawerSwiper];
  self.drawerSwiper = nil;
}

- (void)closeDrawerBySwipe {
  [self.titleBarController buttonTapped:self.titleBarController.drawerButton];
}

- (void)toggleShareDrawer {
  if ( self.shareDrawerOpen ) {
    [self closeShareDrawer];
  } else {
    [self openShareDrawer:[[ContentManager shared] focusedContentObject]];
  }
}

- (void)placeShareDrawer {
  
  UIViewController *titleBar = (UIViewController*)[[Utilities del] globalTitleBar];
  UIViewController *player = (UIViewController*)self.playerWidget;

  NSInteger k = -300;
  
  for ( UIView *v in [self.view subviews] ) {
    if ( v == self.globalShareDrawer.view ) {
      continue;
    }
    if ( v == titleBar.view ) {
      v.layer.zPosition = -100;
      continue;
    }
    if ( v == player.view ) {
      v.layer.zPosition = -101;
      continue;
    }
    if ( v == self.whiteSheet ) {
      v.layer.zPosition = -99;
      continue;
    }
    if ( v == self.globalGradient ) {
      v.layer.zPosition = -102;
      continue;
    }
    v.layer.zPosition = k;
    k--;
  }
  

  
  if ( [Utilities isIOS7] ) {
    [self.globalShareDrawer setAutomaticallyAdjustsScrollViewInsets:NO];
  }
  
  

}





- (void)openShareDrawer:(id)targetContent {
  
  if ( self.shareDrawerOpen ) {
    return;
  }
  

  self.shareDrawerOpen = YES;

#ifdef IPAD_VERSION
  self.sharePopover = [[UIPopoverController alloc]
                                    initWithContentViewController:self.globalShareDrawer];

  
  CGRect raw = [[[Utilities del] globalTitleBar] personalInfoButton].frame;
  CGRect cooked = [self.view convertRect:raw fromView:[[Utilities del] globalTitleBar].view];
  self.sharePopover.delegate = self;
  

  [self.globalShareDrawer.shareMethodTable reloadData];
  
  CGFloat s = [self.globalShareDrawer.shareCells count]*52.0+4.0;
  self.sharePopover.popoverContentSize = CGSizeMake(self.globalShareDrawer.shareMethodTable.frame.size.width,s);
  NSLog(@"Popover content size : %1.1f, %1.1f",self.sharePopover.popoverContentSize.width,self.sharePopover.popoverContentSize.height);
  [self.sharePopover presentPopoverFromRect:cooked
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionUp
                           animated:YES];
#else
  
  
  CGRect raw = [[[Utilities del] globalTitleBar] personalInfoButton].frame;
  CGRect cooked = [self.view convertRect:raw fromView:[[Utilities del] globalTitleBar].view];
  self.globalShareDrawer.view.frame = CGRectMake(self.view.frame.size.width-self.globalShareDrawer.view.frame.size.width,
                                                 cooked.origin.y+cooked.size.height+3.0,
                                                 self.globalShareDrawer.view.frame.size.width,
                                                 self.globalShareDrawer.view.frame.size.height);
  [self.view addSubview:self.globalShareDrawer.view];
  
  /*self.shareDrawerTapDismiss = [[UITapGestureRecognizer alloc]
                                initWithTarget:self
                                action:@selector(closeShareDrawer)];
  
  [self.view addGestureRecognizer:self.shareDrawerTapDismiss];*/
  
#endif

  
  
  
}

- (void)shareDrawerFinishedOpening {
  
}

- (void)closeShareDrawer {
  if ( !self.shareDrawerOpen ) {
    return;
  }
  self.shareDrawerOpen = NO;
  
#ifdef IPAD_VERSION
  [self.sharePopover dismissPopoverAnimated:YES];
#else
  [self.globalShareDrawer.view removeFromSuperview];
  [self.view removeGestureRecognizer:self.shareDrawerTapDismiss];
#endif
  
}

- (void)shareDrawerFinishedClosing {
  for ( unsigned i = 0; i < [self.globalShareDrawer.shareCells count]; i++ ) {
    NSIndexPath *ip = [NSIndexPath indexPathForItem:i inSection:0];
    [self.globalShareDrawer.shareMethodTable deselectRowAtIndexPath:ip animated:YES];
  }
}



#pragma mark - UIPopoverController
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.shareDrawerOpen = NO;
}

#pragma mark - UIScrollView Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  CGFloat offset = scrollView.contentOffset.x/scrollView.frame.size.width;
  self.topicSelector.selectedSegmentIndex = (NSInteger)offset;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"main_scroller_scrolled"
                                                      object:[NSNumber numberWithFloat:offset]];
}

- (void)adjustScrollerSizeForPlayerState {
  CGRect r = CGRectZero;
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.15];
  if ( self.playerDisplaying ) {
    r = CGRectMake(0.0,
                   self.titleBarController.view.frame.size.height,
                   self.mainPageScroller.frame.size.width,
                   self.view.frame.size.height-self.playerWidget.view.frame.size.height);
  } else {
    r = CGRectMake(self.mainPageScroller.frame.origin.x,
                   self.titleBarController.view.frame.size.height,
                   self.mainPageScroller.frame.size.width,
                   self.view.frame.size.height);
  }
  self.mainPageScroller.frame = r;
  self.mainPageScroller.contentSize = CGSizeMake(r.size.width*self.contentVector.count,self.mainPageScroller.frame.size.height);
  [UIView commitAnimations];
  

}

#pragma mark - Player event handling
- (IBAction)volTap:(id)sender {
  CGFloat randy = (CGFloat) (random() % 100)/100;
  [[AudioManager shared] adjustVolume:randy];
}


- (IBAction)buttonTapped:(id)sender {
  if ( sender == self.showOrHidePlayerButton ) {
    if ( self.playerDisplaying ) {
      [self hidePlayer];
    } else {
      [self displayPlayer];
    }
  }
  if ( sender == self.playLocalButton ) {
    // This is some temporary automation to get an onDemand stream playing. TODO: Remove eventually
    self.automating = YES;
    [[AudioManager shared] setRebootStream:YES];
    [self buttonTapped:self.showOrHidePlayerButton];
  }
  if ( sender == self.removeTakeTwoButton ) {
    [[ContentManager shared] removeSegment:[[ContentManager shared] findModelByName:@"Take Two"
                                                                      andType:ModelTypeSegment]
                         fromCollection:[[ContentManager shared] findModelByName:@"Queue"
                                                                      andType:ModelTypeCollection]];
#ifdef DEBUG
    //[self loadListOfSegmentsFromQueue];
#endif
  }
  if ( sender == self.removeOfframpButton ) {
    [[ContentManager shared] removeSegment:[[ContentManager shared] findModelByName:@"Off Ramp"
                                                                      andType:ModelTypeSegment]
                         fromCollection:[[ContentManager shared] findModelByName:@"Queue"
                                                                      andType:ModelTypeCollection]];
#ifdef DEBUG
    //[self loadListOfSegmentsFromQueue];
#endif
  }
  if ( self.returnToLiveButton == sender ) {
    [self.playerWidget overrideStream:nil];
  }
}

- (void)displayPlayer {

  [UIView animateWithDuration:0.25 animations:^{
    self.playerWidget.view.alpha = 1.0;
  }];
  
}

- (void)hidePlayer {
  [UIView animateWithDuration:0.25 animations:^{
    self.playerWidget.view.alpha = 0.0;
  }];
}

- (void)checkAutomation {
  
  if ( self.automating ) {
    if ( self.playerDisplaying ) {
      [self.playerWidget overrideStream:kOndemandURL];
      self.playLocalButton.alpha = 0.5;
      self.playLocalButton.userInteractionEnabled = NO;
    } else {
      self.playLocalButton.alpha = 1.0;
      self.playLocalButton.userInteractionEnabled = YES;
      self.automating = NO;
    }
  } else {
    if ( self.playerDisplaying ) {
      self.playLocalButton.alpha = 0.5;
      self.playLocalButton.userInteractionEnabled = NO;
    } else {
      self.playLocalButton.alpha = 1.0;
      self.playLocalButton.userInteractionEnabled = YES;
    }
  }

}

- (void)killPlayer {
  
  [[DesignManager shared] globalSetTitleTo:@"Show Player"
                                 forButton:self.showOrHidePlayerButton];
  
  //[self.playerWidget.view removeFromSuperview];
  [self.playerWidget hideVolumeSlider];
  
  
  
  [self checkAutomation];
  
}

/*
- (BOOL)shouldAutorotate {
#ifdef SUPPORT_LANDSCAPE
  return YES;
#else
  return NO;
#endif
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAll;
}
*/

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  NSLog(@"Cleaning up due to memory warning...");
  self.programPages = nil;
  [[ContentManager shared] destroyDiskAndMemoryCache];
  
    // Dispose of any resources that can be recreated.
}

@end
