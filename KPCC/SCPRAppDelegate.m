//
//  SCPRAppDelegate.m
//  KPCC
//
//  Created by Ben on 4/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRAppDelegate.h"
#import "SCPRViewController.h"
#import "SCPRDrawerViewController.h"
#import "SCPRQueueCellViewController.h"
#import "SCPRScrollingAssetViewController.h"
#import "global.h"
#import <Parse/Parse.h>
#import "SCPRSpinnerViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRCloakViewController.h"
#import <DCIntrospect-ARC/DCIntrospect.h>

@implementation SCPRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.masterRootController = [[SCPRMasterRootViewController alloc]
                               initWithNibName:[[DesignManager shared]
                                                xibForPlatformWithName:@"SCPRMasterRootViewController"]
                               bundle:nil];
  self.masterRootController.view.autoresizesSubviews = YES;
  
#ifdef USE_PARSE
  [Parse setApplicationId:[[[[FileManager shared] globalConfig] objectForKey:@"Parse"] objectForKey:@"ApplicationId"]
                clientKey:[[[[FileManager shared] globalConfig] objectForKey:@"Parse"] objectForKey:@"ClientKey"]];
#endif
  
#ifdef FAKE_TOUR
  [[ContentManager shared] unregisterPushNotifications];
#endif
  
  if ( [Utilities pureNil:[[ContentManager shared].settings twitterBearerToken]] ) {
    [[SocialManager shared] discreteInlineTwitterAuth];
  }
  
  NSString *pretty = [Utilities prettyShortVersion];
  [[ContentManager shared] patch:pretty];

  [[AnalyticsManager shared] setSavedScreenContent:ScreenContentTypeUnknown];
  [[ContentManager shared] initDataStores];
  
  [[AVAudioSession sharedInstance] setDelegate: self];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
  UInt32 doChangeDefaultRoute = 1;
  AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);

  if ( [Utilities isIOS7] ) {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  }

  self.globalSpinner = [[SCPRSpinnerViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRAltSpinnerViewController"] bundle:nil];
  self.viewController = [[SCPRViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRViewController"] bundle:nil];

  [self.masterRootController.view addSubview:self.viewController.view];
  
  UINavigationController *unc = [[UINavigationController alloc] initWithRootViewController:self.masterRootController];
  unc.navigationBarHidden = YES;
  
  // Boot up all of our analytics: TestFlight, Flurry, New Relic, anything homespun
  [[AnalyticsManager shared] primeAnalytics];
  
  self.globalDrawer = [[SCPRDrawerViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDrawerViewController"] bundle:nil];
  CGFloat adjustment = [Utilities isIOS7] ? 20.0 : 40.0;
  self.globalDrawer.view.frame = CGRectMake(0.0,0.0,
                                            self.globalDrawer.view.frame.size.width,
                                            self.masterRootController.view.frame.size.height+adjustment);
  
  self.window.autoresizesSubviews = NO;
  self.window.backgroundColor = [UIColor blackColor];
  self.window.rootViewController = self.masterRootController;

  self.globalDrawer.view.alpha = 0.0;
  [self.masterRootController.view addSubview:self.globalDrawer.view];
  [self.masterRootController.view sendSubviewToBack:self.globalDrawer.view];
  self.masterRootController.globalGradient = self.viewController.globalGradient;
  
  [self.window makeKeyAndVisible];
  
#if TARGET_IPHONE_SIMULATOR
  [[DCIntrospect sharedIntrospector] start];
#endif
  
  [[DesignManager shared] setPredictedWindowSize:self.window.frame.size];
  
  NSArray *vcTypical = [[DesignManager shared] typicalConstraints:self.viewController.view];
  [self.masterRootController.view addConstraints:vcTypical];
  
  NSArray *typical = [[DesignManager shared] typicalConstraints:self.masterRootController.view];
  [self.window addConstraints:typical];
  
  UILocalNotification *ln = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
  if ( ln ) {
    [self.viewController primeUI:ScreenContentTypeProgramPage
                        newsPath:[[ln userInfo] objectForKey:@"slug"]];
    [[AudioManager shared] startStream:kLiveStreamURL];
    return YES;
  }
  
  if ( [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] ) {
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    [[ContentManager shared] setPendingNotification:[remoteNotification mutableCopy]];
  }

  [[Utilities del] setLaunchFinished:YES];
  
  [self.viewController primeUI:ScreenContentTypeCompositePage newsPath:@""];

  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|
   UIRemoteNotificationTypeBadge|
   UIRemoteNotificationTypeSound];
  
  return YES;
}

- (void)dropOnWindow:(UIView *)view fromView:(UIView *)originalView animateToFrame:(CGRect)animateToFrame completion:(VoidBlock)completion {
  
  CGRect originalFrame = view.frame;
  CGRect cookedFrame = [self.masterRootController.view convertRect:originalFrame fromView:originalView];
  
  [view removeFromSuperview];
  view.frame = cookedFrame;
  [self.masterRootController.view addSubview:view];
  
  [UIView animateWithDuration:.44 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    view.frame = animateToFrame;
  } completion:^(BOOL finished) {
    dispatch_async(dispatch_get_main_queue(), completion);
  }];
  
}

- (void)hideTitleBar {
  self.globalTitleBar.view.alpha = 0.0;
}

- (void)showTitleBar {
  self.globalTitleBar.view.alpha = 1.0;
}

- (void)rotateDrawerForInterfaceOrientation:(UIInterfaceOrientation)orientation {
  
  [self.window setNeedsLayout];

  switch (orientation) {
    case UIInterfaceOrientationLandscapeLeft:
      if ( self.window.frame.size.height > self.window.frame.size.width ) {
        self.window.frame = CGRectMake(self.window.frame.origin.x,
                                       self.window.frame.origin.y,
                                       self.window.frame.size.height,
                                       self.window.frame.size.width);
        NSLog(@"Window dimensions after manual resize : Width: %1.1f, Height: %1.1f",self.window.frame.size.width,
              self.window.frame.size.height);
      }
      
      self.globalDrawer.view.transform = CGAffineTransformMakeRotation([Utilities degreesToRadians:-90.0]);
      self.globalDrawer.view.frame = CGRectMake(0.0,20.0,self.globalDrawer.view.frame.size.width,
                                                self.globalDrawer.view.frame.size.height);
      

      break;
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationLandscapeRight:
    case UIInterfaceOrientationPortraitUpsideDown:
      self.globalDrawer.view.transform = CGAffineTransformMakeRotation(0.0);
      self.globalDrawer.view.frame = CGRectMake(0.0,20.0,self.globalDrawer.view.frame.size.width,
                                                self.globalDrawer.view.frame.size.height);
      break;
      
    default:
      break;
  }
}

- (void)cloakUIWithMessage:(NSString *)message {
  [self cloakUIWithMessage:message andUnfreezeString:@"network_ok"];
}

- (void)blackoutCloak:(VoidBlock)cloakAppeared {
  if ( self.appCloaked ) {
    return;
  }
  
  self.cloak = [[SCPRCloakViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRCloakViewController"] bundle:nil];
  self.cloak.view.frame = CGRectMake(0.0,0.0,self.window.frame.size.width,
                                     self.window.frame.size.height);
  self.cloak.view.backgroundColor = [UIColor blackColor];
  self.cloak.view.alpha = 0.0;
  
  UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  
  [self.cloak.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  [spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  [[DesignManager shared] snapView:self.cloak.view
                       toContainer:self.masterRootController.view];
  
  NSLayoutConstraint *hC = [NSLayoutConstraint constraintWithItem:spinner
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.cloak.view
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0];
  
  NSLayoutConstraint *vC = [NSLayoutConstraint constraintWithItem:spinner
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.cloak.view
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0];
  
  [self.cloak.view addSubview:spinner];
  [self.cloak.view addConstraints:@[ hC, vC ]];
  [spinner startAnimating];
  
  [UIView animateWithDuration:0.25 animations:^{
      self.cloak.view.alpha = 1.0;
  } completion:^(BOOL finished) {
    self.appCloaked = YES;
    cloakAppeared();
  }];
  
}

- (void)uncloakBlackoutUI {
  
}

- (void)cloakUIWithMessage:(NSString *)message andUnfreezeString:(NSString *)string {
  
  if ( self.appCloaked ) {
    return;
  }
  
  self.unfreezeKey = string;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(uncloakUI)
                                               name:string
                                             object:nil];
  
  self.cloak = [[SCPRCloakViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRCloakViewController"] bundle:nil];
  self.cloak.view.frame = CGRectMake(0.0,0.0,self.window.frame.size.width,
                                     self.window.frame.size.height);
  self.cloak.view.backgroundColor = [UIColor blackColor];
  self.cloak.view.alpha = 0.0;
  
  if ( message ) {
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,200.0,170.0)];
    CGRect inset = CGRectInset(messageView.frame, 8.0, 8.0);
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(4.0, 4.0, inset.size.width,
                                                                     inset.size.height)];
    [messageLabel titleizeText:message bold:NO];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines = 0;
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.font = [[DesignManager shared] latoRegular:13.0];
    messageView.backgroundColor = [[DesignManager shared] kpccDarkOrangeColor];
    messageView.alpha = 1.0;

    [messageView addSubview:messageLabel];
    
    [self.cloak.view addSubview:messageView];
    messageView.center = CGPointMake(self.cloak.view.frame.size.width/2.0,
                                     self.cloak.view.frame.size.height/2.0);
    self.cloak.cloakContent = messageView;
  }
  
  [self.masterRootController.view addSubview:self.cloak.view];
  
  [[ContentManager shared] pushToResizeVector:self.cloak];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.33];
  self.cloak.view.alpha = 0.8;
  [UIView commitAnimations];
  
  self.appCloaked = YES;
}

- (void)cloakUIWithSlideshowFromArticle:(NSDictionary *)article {
  
  if ( self.appCloaked ) {
    return;
  }
  
  self.cloak = [[SCPRCloakViewController alloc] initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPRCloakViewController"]
                                                         bundle:nil];
  
  self.cloak.view.autoresizingMask = kGlobalResize;
  self.cloak.view.backgroundColor = [[DesignManager shared] obsidianColor:0.9];
  self.cloak.view.alpha = 0.0;
  self.cloak.view.autoresizesSubviews = YES;
  
  self.slideshowModal = [[SCPRScrollingAssetViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                   xibForPlatformWithName:@"SCPRScrollingAssetViewController"]
                                                                           bundle:nil];
  [self.slideshowModal.view printDimensionsWithIdentifier:@"Slideshow Modal"];
  

  
  self.cloak.cloakContent = self.slideshowModal;
  
  [[ContentManager shared] pushToResizeVector:self.cloak];
  
  self.slideshowModal.view.backgroundColor = [UIColor clearColor];
  self.slideshowModal.leftCurtain.alpha = 0.0;
  self.slideshowModal.rightCurtain.alpha = 0.0;
  self.safeCloak = YES;
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(uncloakUI)];
  
  [self.cloak.view addGestureRecognizer:tap];
  
  [[DesignManager shared] snapView:self.cloak.view
                       toContainer:self.masterRootController.view];
  [[DesignManager shared] snapView:self.slideshowModal.view
                               toContainer:self.cloak.view];
  
  self.slideshowModal.article = article;
  self.slideshowModal.needsSetup = YES;
  
  [UIView animateWithDuration:0.25 animations:^{
      self.cloak.view.alpha = 1.0;
  } completion:^(BOOL finished) {

  }];
  
  self.appCloaked = YES;
}

- (void)cloakUIWithCustomView:(id<Cloakable>)controller dismissible:(BOOL)dismissible {
  [self cloakUIWithCustomView:controller dismissible:dismissible push:0.0];
}

- (void)cloakUIWithCustomView:(id<Cloakable>)controller dismissible:(BOOL)dismissible push:(CGFloat)push {
  if ( self.appCloaked ) {
    return;
  }
  
  self.unfreezeKey = @"fetch_ok";
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(uncloakUI)
                                               name:@"fetch_ok"
                                             object:nil];
  
  self.customCloak = controller;
  
  self.cloak = [[SCPRCloakViewController alloc] initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPRCloakViewController"]
                                                         bundle:nil];
  
  self.cloak.view.frame = CGRectMake(0.0,0.0,self.masterRootController.view.bounds.size.width,
                                     self.masterRootController.view.bounds.size.height);
  self.cloak.view.backgroundColor = [[DesignManager shared] obsidianColor:0.8];
  self.cloak.view.alpha = 0.0;
  self.cloak.view.autoresizingMask = kGlobalResize;
  self.cloak.view.autoresizesSubviews = YES;
  self.cloak.view.tag = 1500;
  
  UIViewController *ctrl = (UIViewController*)controller;
  ctrl.view.center = CGPointMake(self.cloak.view.frame.size.width/2.0,
                                 self.cloak.view.frame.size.height/2.0+push);
  ctrl.view.tag = 1501;
  NSArray *layout = [[DesignManager shared] sizeContraintsForView:ctrl.view];
  [ctrl.view addConstraints:layout];
  
  [[DesignManager shared] snapCenteredView:ctrl.view
                               toContainer:self.cloak.view];
  
  self.cloak.cloakContent = ctrl;
  [[ContentManager shared] pushToResizeVector:self.cloak];
  
  self.safeCloak = YES;
  
  if ( dismissible ) {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(uncloakUI)];
    
    [self.cloak.view addGestureRecognizer:tap];
  }
  
  //[self.masterRootController.view addSubview:self.cloak.view];
  [[DesignManager shared] snapView:self.cloak.view
                       toContainer:self.masterRootController.view];
  
  [UIView animateWithDuration:0.33 animations:^{
    self.cloak.view.alpha = 1.0;
  } completion:^(BOOL finished) {
    self.appCloaked = YES;
  }];
}

- (void)cloakUIWithCustomView:(id<Cloakable>)controller {
  [self cloakUIWithCustomView:controller dismissible:YES];
}

- (void)uncloakUI {
  [self uncloakUI:NO];
}

- (void)uncloakUI:(BOOL)blackout {
  
  if ( self.appIsShowingTour ) {
    return;
  }
  
  if ( [[DesignManager shared] hasBeenInFullscreen] ) {
    [[DesignManager shared] setHasBeenInFullscreen:NO];
  }
  
  if ( !self.cloak ) {
    return;
  }
  
  if ( self.unfreezeKey ) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:self.unfreezeKey
                                                  object:nil];
    
    self.unfreezeKey = nil;
  }
  
  [UIView animateWithDuration:0.25 animations:^{
      self.cloak.view.alpha = 0.0;
  } completion:^(BOOL finished) {
    self.appCloaked = NO;
    
    [self.cloak.view removeFromSuperview];
    self.cloak = nil;
    
    if ( !self.safeCloak ) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"wake_up_ui"
                                                          object:nil];
    } else {
      self.safeCloak = NO;
    }
    
    if ( self.customCloak ) {
      [self.customCloak deactivate];
      self.customCloak = nil;
    }
    if ( self.slideshowModal ) {
      [self.slideshowModal deactivate];
      self.slideshowModal = nil;
    }
    
    if ( !blackout ) {
      [[ContentManager shared] popFromResizeVector];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"app_uncloaked"
                                                        object:nil];
  }];

}

- (SCPRPlayerWidgetViewController*)globalPlayer {
  SCPRViewController *vc = (SCPRViewController*)self.viewController;
  return vc.playerWidget;
}

- (SCPRTitlebarViewController*)globalTitleBar {
  SCPRViewController *vc = (SCPRViewController*)self.viewController;
  return vc.titleBarController;
}

- (void)incrementNewItemCount {
  SCPRPlayerWidgetViewController *player = self.globalPlayer;
  [player setAddedItemsCount:player.addedItemsCount+1];
}

#pragma mark - Main drawer and Share drawer
- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
#ifdef SUPPORT_LANDSCAPE
  return UIInterfaceOrientationMaskAll;
#else
  return UIInterfaceOrientationMaskAllButUpsideDown;
#endif
}

- (void)toggleDrawer {
  if ( self.drawerOpen ) {
    [self closeDrawer];
  } else {
    [self openDrawer];
  }
}

- (void)openDrawer {
  
  [[AnalyticsManager shared] logEvent: @"menu_open_drawer" withParameters:@{}];
  
  self.globalDrawer.view.alpha = 1.0;
  
  CGFloat offset = UIDeviceOrientationIsLandscape(self.masterRootController.interfaceOrientation) ? 260.0 : 240.0;
  self.drawerOpen = YES;
  [[DesignManager shared] applyLeftShadowTo:self.viewController.view];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.2];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  self.bigShadow.alpha = 1.0;
  self.viewController.view.center = CGPointMake(self.viewController.view.center.x+offset,self.viewController.view.center.y);
  [UIView commitAnimations];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"drawer_opened"
                                                      object:nil];
}

- (void)closeDrawer {
  self.drawerOpen = NO;
  
  [[DesignManager shared] applyLeftShadowTo:self.viewController.view];
  [UIView animateWithDuration:0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    self.bigShadow.alpha = 0.0;
    self.viewController.view.frame = CGRectMake(0.0,
                                                0.0,
                                                self.viewController.view.bounds.size.width,
                                                self.viewController.view.bounds.size.height);
  } completion:^(BOOL finished) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"drawer_closed"
                                                        object:nil];
  }];
}

- (void)armGlobalDismiss:(id)sender {
  [self disarmGlobalDismiss];
  if ( ![sender respondsToSelector:@selector(globalDismiss:)] ) {
    // Fail silently for now
    return;
  }
  self.tapper = [[UITapGestureRecognizer alloc] initWithTarget:sender
                                                        action:@selector(globalDismiss:)];
  [self.viewController.view addGestureRecognizer:self.tapper];
  
}

- (void)disarmGlobalDismiss {
  for ( UIGestureRecognizer *gr in [self.viewController.view gestureRecognizers] ) {
    [self.viewController.view removeGestureRecognizer:gr];
  }
  if ( self.tapper ) {
    self.tapper = nil;
  }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  
#ifdef USE_PARSE
  // Store the deviceToken in the current Installation and save it to Parse.
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  [currentInstallation setDeviceTokenFromData:deviceToken];
  [currentInstallation saveInBackground];
  
  NSString *pushChannel = kPushKeyBreakingNews;
#ifdef SANDBOX_PUSHES
  pushChannel = kPushKeySandbox;
#endif
  [currentInstallation addUniqueObject:pushChannel
                                forKey:@"channels"];
  [currentInstallation saveInBackground];
#endif
  
  const unsigned *tokenBytes = [deviceToken bytes];
  NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                        ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                        ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                        ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
  
  NSLog(@"Device token for APNS : %@",hexToken);
  
  [[ContentManager shared].settings setPushToken:hexToken];
  [[ContentManager shared] writeSettings];
  
  switch ([self operatingWithPushType]) {
    case PushTypeEvents:
    case PushTypeBreakingNews:

      break;
    case PushTypeUnknown:
      default:
      break;
  }
  [self setOperatingWithPushType:PushTypeUnknown];
  NSLog(@" ***** REGISTERED APNS SUCCESSFULLY ***** ");
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@" ***** REGISTER APNS FAILURE ***** : %@ ",[error localizedDescription]);
  [[ContentManager shared].settings setPushToken:@""];
  [[ContentManager shared] writeSettings];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [FBSession.activeSession handleOpenURL:url]; 
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [[AnalyticsManager shared] setSavedScreenContent:[[AnalyticsManager shared] screenContent]];
  [[AnalyticsManager shared] terminateTimedSessionForContentType:[[AnalyticsManager shared] screenContent]];
  
  NSLog(@"App is going to resign active ...");
  [[AudioManager shared] watchAudioThroughput:self];
  
  if ( [[QueueManager shared] currentlyPlayingSegment] ) {
    NSLog(@"Saving context on resign active");
    [[ContentManager shared] saveContextOnMainThread];
  }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  self.backgrounding = YES;
  
  [[ContentManager shared].settings setLeftAppAt:[NSDate date]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  [[ScheduleManager shared] disarmScheduleUpdater];
 
  // Handle ad session
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    [[AnalyticsManager shared] logEvent:@"ad_was_loaded_but_avoided"
                         withParameters:@{}];
    [self.masterRootController undeliverAd];
  }
  [[ContentManager shared] resetAdTracking];
  
  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:[[ContentManager shared] audioMetaData]];
  }
  
  [[AnalyticsManager shared] setSavedScreenContent:[[AnalyticsManager shared] screenContent]];
  [[AnalyticsManager shared] terminateTimedSessionForContentType:[[AnalyticsManager shared] screenContent]];
  [[AudioManager shared] disarmAudioParsingTimer];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

  [[AudioManager shared] removeWatcher:self];
  
  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    [[AudioManager shared] armAudioParsingTimer];
  }
  
  [[ScheduleManager shared] armScheduleUpdater];
  
  [[ContentManager shared] setSwipeCount:0];
  [[ContentManager shared].settings setLeftAppAt:[NSDate date]];
  
  
  if ( self.backgrounding ) {
    [[NetworkManager shared] fetchContentForScheduleThisWeek:[ScheduleManager shared]];
  }
  
  [self.globalPlayer prime];
  [self.viewController.globalShareDrawer buildCells];
  
  if ( [[AnalyticsManager shared] savedScreenContent] != ScreenContentTypeUnknown ) {    
    [[AnalyticsManager shared] openTimedSessionForContentType:[[AnalyticsManager shared] savedScreenContent]];
    [[AnalyticsManager shared] setSavedScreenContent:ScreenContentTypeUnknown];
  }
  
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  self.backgrounding = NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  
  if ( [[SocialManager shared] isAuthenticatedWithFacebook] ) {
    if ( [FBSession activeSession] ) {
      [FBSession.activeSession handleDidBecomeActive];
    }
  }
  
  if ( [[AudioManager shared] audioWasInterrupted] ) {
    [[AudioManager shared] setAudioWasInterrupted:NO];
    [[AudioManager shared] unpauseStream];
  }
  
  [[ScheduleManager shared] armScheduleUpdater];
  
  [self.globalDrawer respin];
  
  if ( [[NetworkManager shared] checkNetworkHealth:nil] == NetworkHealthAllOK ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:self.unfreezeKey object:nil];

    if ( self.serverDown ) {
      [self.viewController primeUI:ScreenContentTypeCompositePage
                          newsPath:@""];
    }
  } else {
    [self cloakUIWithMessage:@"This app requires a connection to the internet. Please try again when one is available"];
    return;
  }
  
  [[self.viewController globalShareDrawer] buildCells];
  
#ifdef PARSE_ADMIN_OPERATION
  [[ContentManager shared] checkCurrentVersion:self.viewController];
#endif
  [[ContentManager shared] checkForPromotionalMaterial];
  [[AnalyticsManager shared] retrieveAdSettings];

  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  if (currentInstallation.badge != 0) {
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
  }
  
  if ( [UIApplication sharedApplication].applicationIconBadgeNumber > 0 ) {
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
    if ( ![Utilities pureNil:[[ContentManager shared].settings lastAlertPayload]] ) {
      [self.masterRootController showBreakingNewsWithMessage:[[ContentManager shared].settings lastAlertPayload] action:^{
        [self.masterRootController hideBreakingNews];
      }];
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  }
  
  [[NetworkManager shared] fetchContentForScheduleThisWeek:[ScheduleManager shared]];}

- (void)applicationWillTerminate:(UIApplication *)application {
  
  if ( [[QueueManager shared] currentlyPlayingSegment] ) {
    NSLog(@"Saving context on termination");
    [[ContentManager shared] saveContextOnMainThread];
  }
  
  [[AnalyticsManager shared] setSavedScreenContent:[[AnalyticsManager shared] screenContent]];
  [[AnalyticsManager shared] terminateTimedSessionForContentType:[[AnalyticsManager shared] screenContent]];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
  
  if ( application.applicationState == UIApplicationStateInactive ) {
    NSDictionary *uinfo = [notification userInfo];
    [self.viewController primeUI:ScreenContentTypeProgramPage
                        newsPath:[uinfo objectForKey:@"title"]];
    [[AudioManager shared] startStream:kLiveStreamURL];
  }
  
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  if ( application.applicationState == UIApplicationStateActive ) {
    [[ContentManager shared] displayPushMessageWithPayload:userInfo];
  } else {
    [[ContentManager shared] setPendingNotification:[userInfo mutableCopy]];
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
    
    NSLog(@"Received breaking news notification");
    if ( [[AnalyticsManager shared] screenContent] != ScreenContentTypeCompositePage ) {
      [self.viewController primeUI:ScreenContentTypeCompositePage
                          newsPath:@""];
    }
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( object == [[AudioManager shared] audioPlayer] ) {
    CGFloat old = [[change objectForKey:@"old"] floatValue];
    CGFloat neu = [[change objectForKey:@"new"] floatValue];
    if ( old > 0.0 && neu == 0.0 ) {
      NSLog(@" ** Audio being interrupted, tell the app ... ");
      [[AudioManager shared] setAudioWasInterrupted:YES];
      [[AudioManager shared] pauseStream];
    }
  }
}

@end
