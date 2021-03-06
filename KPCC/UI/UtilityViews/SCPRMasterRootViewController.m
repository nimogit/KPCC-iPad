//
//  SCPRMasterRootViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRMasterRootViewController.h"
#import "SCPRPlayerWidgetViewController.h"
#import "SCPRAppDelegate.h"
#import "SCPRTitlebarViewController.h"
#import "global.h"
#import "SCPRViewController.h"
#import "SCPRIntroductionViewController.h"
#import "SCPRSingleArticleViewController.h"
#import "SCPRViewController.h"

@interface SCPRMasterRootViewController ()

@end

@implementation SCPRMasterRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  
#ifndef TRACK_SCROLLING_PROGRESS
  [self.hudInformationLabel removeFromSuperview];
#else
  
  self.hudInformationLabel.text = @"";
  
#endif
  
  self.cloakView.alpha = 0.0;
  if ( [Utilities isIOS7] ) {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.needsAnchoring = YES;
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(movieEnteredFullscreen)
                                               name:@"UIMoviePlayerControllerDidEnterFullscreenNotification"
                                             object:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(movieExitedFullscreen)
                                               name:@"UIMoviePlayerControllerDidExitFullscreenNotification"
                                             object:nil];
  
  // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {

}

- (void)viewDidAppear:(BOOL)animated {


  

}

- (void)viewDidLayoutSubviews {

}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#ifdef TRACK_SCROLLING_PROGRESS
  if ( object == self.adPresentationView ) {
    CGPoint o = [[change objectForKey:@"new"] CGPointValue];
    [self.hudInformationLabel titleizeText:[NSString stringWithFormat:@"OffsetX : %1.1f",o.x]
                                      bold:YES];
  }
#endif
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  if ( [content count] > 0 ) {

    NSAssert([NSThread isMainThread], @"Method called using a thread other than main!");
    
    SCPRSingleArticleViewController *sac = [[SCPRSingleArticleViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                     xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                                                                             bundle:nil];
    sac.fromSnapshot = YES;
    sac.relatedArticle = [content objectAtIndex:0];
    sac.wantsFullScreenLayout = YES;
    
    
    sac.parentEditionAtom = self;
    self.pushedContent = sac;
    
    SCPRViewController *vc = [[Utilities del] viewController];
    UINavigationController *container = (UINavigationController*)vc.pushedContent;
    [container pushViewController:sac
                                              animated:YES];
    
    sac.supplementalContainer = self;
    [sac arrangeContent];
    
    
    [[ContentManager shared] pushToResizeVector:sac];
    [[ContentManager shared] setFocusedContentObject:sac.relatedArticle];
    
    [[[Utilities del] globalTitleBar] morph:BarTypeModal
                                  container:sac];
    
    [[[Utilities del] globalTitleBar]
     applyBackButtonText:@"HOME"];
    
  }
}

- (void)contentFinishedDisplaying {
  self.pushedContent = nil;
  [[[Utilities del] globalTitleBar] applyDonateButton];
}

- (void)displayAtomicArticleWithURL:(NSString *)url {
  if ( [[ContentManager shared] isKPCCURL:url] ) {
    [[NetworkManager shared] fetchContentForSingleArticle:url
                                                  display:self];
  } else {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    SCPRExternalWebContentViewController *external = [[SCPRExternalWebContentViewController alloc]
                                                      initWithNibName:[[DesignManager shared]
                                                                       xibForPlatformWithName:@"SCPRExternalWebContentViewController"]
                                                      bundle:nil];
    external.fromEditions = NO;
    external.view.frame = external.view.frame;
    
    if ( [Utilities isIOS7] ) {
      CGFloat adjuster = [Utilities isLandscape] ? 20.0 : 20.0;
      external.webContentView.frame = CGRectMake(external.webContentView.frame.origin.x,
                                                 external.webContentView.frame.origin.y+40.0,
                                                 external.webContentView.frame.size.width,
                                                 external.webContentView.frame.size.height-adjuster);
    }
    
    
    [[[Utilities del] globalTitleBar] morph:BarTypeExternalWeb
                                  container:external];
    
    
    SCPRViewController *vc = [[Utilities del] viewController];
    UINavigationController *container = (UINavigationController*)vc.pushedContent;
    [container pushViewController:external
                         animated:YES];
    
    [external prime:request];
    

    self.pushedContent = external;
    external.supplementalContainer = self;
    
    external.bensOffbrandButton = [[[Utilities del] globalTitleBar] parserOrFullButton];
    
    [external.bensOffbrandButton addTarget:external
                                    action:@selector(buttonTapped:)
                          forControlEvents:UIControlEventTouchUpInside];
    
  }
}

#pragma mark - GLobal display
- (void)showIntro {
  
  //if ( ![Utilities isIOS7] ) {
    [[Utilities del] setAppIsShowingTour:YES];
    
    SCPRIntroductionViewController *ivc = [[SCPRIntroductionViewController alloc]
                                           initWithNibName:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRIntroductionViewController"]
                                           bundle:nil];
    

    
    [ivc setNeedsSnap:YES];
    [[DesignManager shared] snapView:ivc.view
                         toContainer:self.view];
    
    ivc.view.alpha = 0.0;
    self.introView = ivc;
    self.introDisplaying = YES;
    
    [[ContentManager shared] pushToResizeVector:ivc];
    
    if ( [Utilities isIOS7] ) {
      //[self setNeedsStatusBarAppearanceUpdate];
    } else {
      [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    [UIView animateWithDuration:0.33 animations:^{
      ivc.view.alpha = 1.0;
    }];
  /*} else {
    [[ContentManager shared].settings setOnboardingShown:YES];
    [[ContentManager shared] setSkipParse:YES];
    [[ContentManager shared] writeSettings];
  }*/
  
}

- (void)hideIntro {
  
  self.introDisplaying = NO;
  
  if ( [Utilities isIOS7] ) {
    //[self setNeedsStatusBarAppearanceUpdate];
  } else {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
  }
  
  [[ContentManager shared] editPushForBreakingNews:YES];
  [[ContentManager shared] popFromResizeVector];
  
  [[Utilities del] setAppIsShowingTour:NO];
  [[Utilities del] uncloakUI];
  
  SCPRIntroductionViewController *ivc = (SCPRIntroductionViewController*)self.introView;
  [UIView animateWithDuration:0.33 animations:^{
    ivc.view.alpha = 0.0;
  } completion:^(BOOL finished) {
    [ivc.view removeFromSuperview];
    self.introView = nil;
  }];
  
}

- (void)movieEnteredFullscreen {

}

- (void)movieExitedFullscreen {

  
}

- (void)showBreakingNewsWithMessage:(NSString *)message action:(BreakingInteractionCallback)callback {
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(resetFrame)
                                               name:@"breaking_news_dismissed"
                                             object:nil];
  // Save this just in case
  [[ContentManager shared] stubForBreakingNews:[[ContentManager shared].settings lastAlertPayload]];
  
  [[ContentManager shared].settings setLastAlertPayload:@""];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  
  [self.breakingNewsOverlay showOnView:self withMessage:message action:callback];
  
  SCPRViewController *vc = [[Utilities del] viewController];
  
  self.savedYOffset = vc.mainPageScroller.contentOffset.y;
  
  CGFloat modifier = [Utilities isIOS7] ? 60.0 : 40.0;
  CGFloat yDelta = (-1.0*self.breakingNewsOverlay.view.frame.size.height)+modifier;
  [vc.mainPageScroller setContentOffset:CGPointMake(0.0, yDelta)
                               animated:YES];
  
  self.breakingNewsShowing = YES;
  
}

- (void)resetFrame {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"breaking_news_dismissed"
                                                object:nil];
  
  if ( self.breakingNewsShowing ) {
    [self hideBreakingNews];
  }

}

- (void)hideBreakingNews {
  
  self.breakingNewsShowing = NO;
  
  [[ContentManager shared].settings setLastAlertPayload:@""];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  
  SCPRViewController *vc = [[Utilities del] viewController];
  
  CGFloat yDelta = self.savedYOffset;
  
  [UIView animateWithDuration:0.22 animations:^{
    [vc.mainPageScroller setContentOffset:CGPointMake(0.0, yDelta)
                                 animated:NO];
  } completion:^(BOOL finished) {
    [self.breakingNewsOverlay hide];
  }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
  
  return UIInterfaceOrientationMaskAllButUpsideDown;
  
}

- (void)deliverAd:(UISwipeGestureRecognizerDirection)direction intoView:(UIView *)scroller {
  [self deliverAd:direction intoView:scroller silence:self.adSilenceVector];
}

/******************************************************************************/
// -- Developer Note --
//
// This method is actually called when the user reaches the penultimate swipe ([[AnalyticsManager shared] numberOfSwipesPerAd]-1) so
// it can prepare the ad offscreen in the direction the user appears to have been swiping.
//


- (void)deliverAd:(UISwipeGestureRecognizerDirection)direction intoView:(UIView *)scroller silence:(NSMutableArray *)silenceVector {
#ifdef ENABLE_ADS
  
  if ( ![scroller isKindOfClass:[UIScrollView class]] ) {
    NSLog(@"Delivering ads on non-scrollviews is unsupported");
    return;
  }
  
  if (silenceVector) {
    self.adSilenceVector = silenceVector;
  }

#ifdef NATIVE_ADS

  [[ContentManager shared] setAdCount:[[ContentManager shared] adCount]+1];
  
  // Set previous DFPInterstitial object and its delegate to nil.
  self.interstitial.delegate = nil;
  self.interstitial = nil;
  
  self.interstitial = [[GADInterstitial alloc] init];
  self.interstitial.adUnitID = [NSString stringWithFormat:@"/%@/%@",[[AnalyticsManager shared] adVendorID],
                                [[AnalyticsManager shared] adUnitID]];
  self.interstitial.delegate = self;
  

  GADRequest *request = [GADRequest request];

  #if TARGET_IPHONE_SIMULATOR
    request.testDevices = [NSArray arrayWithObjects:GAD_SIMULATOR_ID, nil];
  #endif

  
  [self.interstitial loadRequest:request];
#else
  
  
  // Non-native ghetto ads.
  self.adPresentationView = scroller;
  
#ifdef TRACK_SCROLLING_PROGRESS
    [self.adPresentationView addObserver:self
                              forKeyPath:@"contentOffset"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
#endif


  self.dfpAdViewController = [[SCPRDFPViewController alloc]
                              initWithNibName:[[DesignManager shared]
                                               xibForPlatformWithName:@"SCPRDFPViewController"]
                              bundle:nil];
  self.dfpAdViewController.view.frame = self.dfpAdViewController.view.frame;
  [self.adPresentationView addSubview:self.dfpAdViewController.view];
  NSLog(@"Ad presentation dimensions : W: %1.1f, H: %1.1f",self.adPresentationView.frame.size.width,self.adPresentationView.frame.size.height);
  
  CGFloat xDelta = direction == UISwipeGestureRecognizerDirectionLeft ? self.adPresentationView.frame.size.width : -1.0*self.adPresentationView.frame.size.width;
  CGPoint offset = [(UIScrollView*)self.adPresentationView contentOffset];
  xDelta = offset.x + xDelta;
  
  NSString *alFormat = [NSString stringWithFormat:@"H:|-(%ld)-[ad(%1.1f)]",(long)xDelta,self.adPresentationView.frame.size.width];
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:alFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"ad" : self.dfpAdViewController.view }];
  NSString *valFormat = [NSString stringWithFormat:@"V:|[ad(%1.1f)]|",self.adPresentationView.frame.size.height];
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:valFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"ad" : self.dfpAdViewController.view }];
  
  [self.dfpAdViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self.adPresentationView addConstraints:hConstraints];
  [self.adPresentationView addConstraints:vConstraints];

  if ([Utilities isIOS7]) {
    [(UIScrollView*)self.adPresentationView setClipsToBounds:NO];
  } else {
    [(UIScrollView*)self.adPresentationView setClipsToBounds:NO];

  }
  
  self.dfpAdViewController.view.alpha = 1.0;
  self.dfpAdViewController.delegate = self;
  [self.dfpAdViewController loadDFPAd];
  
#endif // if native_ads
  
#endif // if enable_ads
}

/***********************************************************************************/
// -- Developer Note --
//
// This method serves to readjust the ad to the appropriate position once the scroller redraws itself. It's mainly for the SingleArticleCollectionView
// as that view uses some trickery as it scrolls: Consider three screens where screen "1" is onscreen and screen "0" and "2" are offscreen to the left and right.
//
//  ex 1:   0 --[ 1 ]-- 2     contentOffset.x: 768.0
//
// When deliver ad is called in the SingleArticleCollectionViewController context, if the user is swiping left then the ad will be overlaid on top of screen "2"
// in anticipation of the user scrolling to it.
//
//                     Ad
//  ex 2:   0 --[ 1 ]-- 2     contentOffset.x: 768.0
//
// After a swipe left, the view is temporarily shuffled so it looks like this:
//
//                    Ad
//  Swipe Left:  1 --[ 2 ]-- X    contentOffset.x: 1536.0
//
// Once this scroll happens the view corrects itself by reshifting the contentOffset of the scroller such that the new views take their places as they were in ex 1.
// However because the contentOffset will shift from an x value of 1536.0 back to 768.0 the ad needs to be pulled with it, which is what preserveAd does.
//
//  (0 was 1)  1 was 2   2 was "X"
//              Ad<---
//  ex 3:  0 --[ 1 ]-- 2          contentOffset.x: 768.0<--- (from 1536.0)
//
- (void)preserveAd {
  
#ifndef NATIVE_ADS
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    CGPoint offset = [(UIScrollView*)self.adPresentationView contentOffset];
    
    CGFloat xD = offset.x/*self.adPresentationView.frame.size.width*/;
    if ( offset.x == 0.0 ) {
      xD = 0.0;
    }
    self.dfpAdViewController.view.frame = CGRectMake(xD,
                                                     self.dfpAdViewController.view.frame.origin.y,
                                                     self.dfpAdViewController.view.frame.size.width,
                                                     self.dfpAdViewController.view.frame.size.height);
    [self.adPresentationView bringSubviewToFront:self.dfpAdViewController.view];
  }
#endif

}

- (void)undeliverAd {
  
  /*self.dfpAdViewController.view.alpha = 0.0;
  
  [self.dfpAdViewController.view removeFromSuperview];*/
  
  if ( [[ContentManager shared] adCount] > 0 ) {
    [[ContentManager shared] setAdCount:[[ContentManager shared] adCount]-1];
  }
  
  if ( [[ContentManager shared] swipeCount] > 0 ) {
    [[ContentManager shared] setSwipeCount:[[ContentManager shared] swipeCount]-1];
  }
  
  for ( UIView *v in [self adSilenceVector] ) {
    v.alpha = 1.0;
  }
  
  [self.adSilenceVector removeAllObjects];
  
  [[ContentManager shared] setAdIsDisplayingOnScreen:NO];
  [[ContentManager shared] setAdReadyOffscreen:NO];
  
}

- (void)killAdOffscreen:(AdKilledCompletion)completion {
  
  [UIView animateWithDuration:0.11 animations:^{
    self.dfpAdViewController.view.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self undeliverAd];
    dispatch_async(dispatch_get_main_queue(), completion);
  }];

}

- (void)killAdOnscreen:(AdKilledCompletion)completion {
  [UIView animateWithDuration:0.11 animations:^{
    self.dfpAdViewController.view.alpha = 0.0;
  } completion:^(BOOL finished) {
    [(UIScrollView*)self.adPresentationView setScrollEnabled:YES];
    [[ContentManager shared] setAdIsDisplayingOnScreen:NO];
 
    if ( completion ) {
      dispatch_async(dispatch_get_main_queue(), completion);
    }
  }];
}





- (void)puntToSafariWithURL:(NSString *)url {
  NSURL *urlObj = [NSURL URLWithString:url];
  [[UIApplication sharedApplication] openURL:urlObj];
}

- (void)cloak:(BOOL)spinner {
  [UIView animateWithDuration:0.22 animations:^{
    self.cloakView.alpha = spinner ? .33 : 1.0;
    if ( spinner ) {
      self.spinner.alpha = 1.0;
      [self.spinner startAnimating];
    }
  }];
}

- (void)fullCloak {
  [UIView animateWithDuration:0.22 animations:^{
    self.cloakView.alpha = 1.0;
    self.spinner.alpha = 1.0;
    [self.spinner startAnimating];
  }];
}

- (void)cloak {
  [self cloak:YES];
}

- (void)uncloak {
  [UIView animateWithDuration:0.22 animations:^{
    self.cloakView.alpha = 0.0;
    self.spinner.alpha = 0.0;
  }];
}

- (void)bringUpQueue {
  
  if ( [Utilities isIOS7] ) {
    [self setNeedsStatusBarAppearanceUpdate];
  }
  
  self.frozenOrientation = self.interfaceOrientation;
  self.queueViewController = [[SCPRQueueViewController alloc]
                              initWithNibName:[[DesignManager shared]
                                               xibForPlatformWithName:@"SCPRQueueViewController"]
                              bundle:nil];
  self.queueViewController.parentRoot = self;
  
  [self addChildViewController:self.queueViewController];
  
  self.queueViewController.view.frame = CGRectMake(0.0,self.view.frame.size.height,
                                                   self.queueViewController.view.frame.size.width,
                                                   self.queueViewController.view.frame.size.height);
  [self.view addSubview:self.queueViewController.view];
  [self.queueViewController primeQueueForState];
  
  [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    self.queueViewController.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                     self.view.frame.size.height);
  } completion:^(BOOL finished) {
    
  }];
}

- (void)hideQueue {
  [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    self.queueViewController.view.frame = CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width,
                                                     self.view.frame.size.height);
  } completion:^(BOOL finished) {
    [self.queueViewController.view removeFromSuperview];
    self.queueViewController = nil;
  }];
}

- (void)invalidateStatusBar {
  if ( [Utilities isIOS7] ) {
    [self setNeedsStatusBarAppearanceUpdate];
  }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
  return self.introDisplaying;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return YES;
}

/*******************************************************************/
// -- Developer Note --
// This is where the master root view controller processes the resize vector. It calls all handleRotationPre methods
// here, and then calls handleRotationPost methods in the didRotateToInterfaceOrientation below
//
//
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  /*NSLog(@"Going to rotate %d in rotation queue",[[ContentManager shared].resizeVector count]);
  NSMutableArray *vector = [[ContentManager shared] resizeVector];
  

  
  [self.view bringSubviewToFront:self.cloakView];
  
  if ( [vector count] > 0 ) {
    [UIView animateWithDuration:0.12 animations:^{
      self.cloakView.alpha = 0.53;
      self.spinner.alpha = 1.0;
      [self.spinner startAnimating];
    } completion:^(BOOL finished) {
      for ( id<Rotatable> r in vector ) {
        [r handleRotationPre];
      }
   // }];
  }*/
  
  if ( ![Utilities isIOS7] ) return;
  
  if ( [[[Utilities del] viewController] shareDrawerOpen] ) {
    [[[Utilities del] viewController] closeShareDrawer];
  }
  

  
  CGSize newSize = CGSizeZero;
  if ( toInterfaceOrientation == UIInterfaceOrientationPortrait ||
      toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
    newSize = CGSizeMake(768.0f, 1024.0f);
  } else {
    newSize = CGSizeMake(1024.0f, 768.0f);
  }
  

  
  [[DesignManager shared] setPredictedWindowSize:newSize];
  
  NSArray *wc = [[Utilities del] windowConstraints];
  for ( NSLayoutConstraint *c in wc ) {
    if ( [c firstAttribute] == NSLayoutAttributeWidth ) {
      [c setConstant:[[DesignManager shared] predictedWindowSize].width];
    } else {
      [c setConstant:[[DesignManager shared] predictedWindowSize].height];
    }
  }
  
  UIWindow *window = [[Utilities del] window];
  [window layoutIfNeeded];
  
  [self.view layoutIfNeeded];
  
  SCPRPlayerWidgetViewController *player = [[Utilities del] globalPlayer];
  [player orient];
  [player.queueViewController prime];
  
  //if ( ![Utilities isIOS7] ) {
    SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
    tb.pageTitleLabel.center = CGPointMake(tb.view.bounds.size.width/2.0,
                                         tb.view.bounds.size.height/2.0);
  
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
    [self.view layoutIfNeeded];
  
  if ( ![Utilities isIOS7] ) {
  
    SCPRViewController *scprView = [[Utilities del] viewController];
    [[scprView view] setNeedsUpdateConstraints];
    [[scprView view] updateConstraintsIfNeeded];
    [[scprView view] setNeedsLayout];
    [[scprView view] layoutIfNeeded];
  
  
    NSMutableArray *vector = [[ContentManager shared] resizeVector];
    for ( id<Rotatable> r in vector ) {
      [r handleRotationPost];
    }
    
  } else {
    NSMutableArray *vector = [[ContentManager shared] resizeVector];
    for ( id<Rotatable> r in vector ) {
      [r handleRotationPre];
    }
  }

}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  
  [[DesignManager shared] setPredictedWindowSize:size];
  
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  
  SCPRPlayerWidgetViewController *player = [[Utilities del] globalPlayer];
  [player orient];
  [player.queueViewController prime];
  
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  tb.pageTitleLabel.center = CGPointMake(tb.view.bounds.size.width/2.0,
                                         tb.view.bounds.size.height/2.0);
  
  
  [self.view setNeedsUpdateConstraints];
  [self.view updateConstraintsIfNeeded];
  [self.view layoutIfNeeded];
  
  if ( ![Utilities isIOS7] ) {
    SCPRViewController *scprView = [[Utilities del] viewController];
    [[scprView view] setNeedsUpdateConstraints];
    [[scprView view] updateConstraintsIfNeeded];
    [[scprView view] setNeedsLayout];
    [[scprView view] layoutIfNeeded];

    
    NSMutableArray *vector = [[ContentManager shared] resizeVector];
    for ( id<Rotatable> r in vector ) {
      [r handleRotationPost];
    }
  }
  
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

  if ( [Utilities isIOS7] ) {
    
    [[[Utilities del] window] layoutIfNeeded];
    [self.view layoutIfNeeded];
    SCPRViewController *scprView = [[Utilities del] viewController];
    [[scprView view] setNeedsUpdateConstraints];
    [[scprView view] updateConstraintsIfNeeded];
    [[scprView view] setNeedsLayout];
    [[scprView view] layoutIfNeeded];
    
    CGRect r = [[[Utilities del] window] frame];
    NSLog(@"Main Window after rotation : %1.1fw x %1.1fh",r.size.width,r.size.height);
    [self.view printDimensionsWithIdentifier:@"MASTER ROOT CONTROLLER"];
    
    NSMutableArray *vector = [[ContentManager shared] resizeVector];
    for ( id<Rotatable> r in vector ) {
      [r handleRotationPost];
    }
    
  }
}

- (void)viewWillLayoutSubviews {

}

- (void)handleRotationPre {
  
}

- (void)handleRotationPost {
  
}





@end
