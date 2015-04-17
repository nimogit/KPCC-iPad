//
//  SCPRSingleArticleCollectionViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSingleArticleCollectionViewController.h"
#import "SCPRSingleArticleViewController.h"
#import "SCPRNewsPageContainerController.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRDeluxeNewsViewController.h"
#import "SCPRDFPViewController.h"
#import "UIView+PrintDimensions.h"

static NSInteger kCacheLockDistance = 3;

@interface SCPRSingleArticleCollectionViewController ()

@end

@implementation SCPRSingleArticleCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.contentLock = NO;
  self.fetchLock = NO;
  self.wingArticles = [[NSMutableDictionary alloc] init];
  self.articles = [[NSMutableArray alloc] init];
  self.visualComponents = [[NSMutableArray alloc] init];
  self.queuedForTrash = [[NSMutableDictionary alloc] init];
  self.webcontentQueue = [[NSOperationQueue alloc] init];
  self.articlePageViewController = self;
  self.articlePageViewController.delegate = self;
  self.articlePageViewController.dataSource = self;
  
  
  [self.articlePageViewController.view printDimensionsWithIdentifier:@"Article Page Container"];
  
  self.untouchables = [[NSMutableArray alloc] init];
  
  [self.view setTranslatesAutoresizingMaskIntoConstraints:YES];
  [self.view printDimensionsWithIdentifier:@"Single Article Collection"];
  
}



- (SCPRSingleArticleViewController*)prepareArticleViewWithIndex:(NSInteger)index {
  NSDictionary *relatedArticle = [self.articles objectAtIndex:index];
  SCPRSingleArticleViewController *articleView = [[SCPRSingleArticleViewController alloc]
                                                  initWithNibName:[[DesignManager shared]
                                                                   xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                                  bundle:nil];
  articleView.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                      self.view.frame.size.height);
  
  [articleView setParentCollection:self];
  [articleView setIndex:index];
  [articleView setRelatedArticle:relatedArticle];
  articleView.webContentLoader.loadingSkeletonContent = NO;
  articleView.parentNewsPage = self.parentContainer;
  [articleView arrangeContent];
  
  [articleView.view setNeedsLayout];
  [articleView.view layoutIfNeeded];
  
  [self.untouchables addObject:articleView];
  
  return articleView;
}

- (void)sweep {
  NSMutableArray *tmp = [NSMutableArray new];
  
  for ( id<Pageable,Deactivatable> article in self.untouchables ) {
    if ( abs(article.index - self.currentIndex) > kCacheLockDistance &&
         self.currentIndex > (kCacheLockDistance - 1) ) {
      [[ContentManager shared] disposeOfObject:article protect:YES];
    } else if ( self.currentIndex < kCacheLockDistance && article.index >= ([self.articles count]-(kCacheLockDistance-1) )) {
      [tmp addObject:article];
    } else if ( abs(article.index - self.currentIndex) > kCacheLockDistance ) {
      [[ContentManager shared] disposeOfObject:article protect:YES];
    } else {
      [tmp addObject:article];
    }
  }
  self.untouchables = tmp;
  [[ContentManager shared] emptyTrash];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [[DesignManager shared] setInSingleArticle:YES];
}

- (void)viewWillAppear:(BOOL)animated {
  [[[Utilities del] globalTitleBar] applyKpccLogo];
}

- (void)viewDidLayoutSubviews {

}

- (void)viewDidDisappear:(BOOL)animated {
  if ( self.trash ) {
    self.trash = NO;
  }
}

- (void)prepareArticleView:(SCPRSingleArticleViewController *)savc {
  
}

- (void)setupWithCollection:(NSArray *)articles beginningAtIndex:(NSInteger)index processIndex:(BOOL)processIndex {
  
  if (index >= [articles count]) {
    return;
  }
  
  for ( UIViewController *vc in self.childViewControllers ) {
    [self.untouchables addObject:vc];
  }
  
  self.articles = [NSMutableArray arrayWithArray:articles];
  self.currentIndex = index;

  
  SCPRSingleArticleViewController *articleView = [self prepareArticleViewWithIndex:index];
  self.visualComponents = [NSMutableArray new];
  [self.visualComponents addObject:articleView];
  self.currentPage = articleView;
  
  __block SCPRSingleArticleCollectionViewController *weakself_ = self;
  [self.articlePageViewController setViewControllers:@[articleView]
                                           direction:UIPageViewControllerNavigationDirectionForward
                                            animated:NO
                                          completion:^(BOOL finished) {
                                            
                                            [articleView.view printDimensionsWithIdentifier:@"Single Article View"];
                                            weakself_.view.alpha = 1.0;
                                            articleView.view.alpha = 1.0;
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                              
                                              if ( [[DesignManager shared] reservedRotationFlag] ) {
                                                [[DesignManager shared] setReservedRotationFlag:NO];
                                                [articleView openShareModal];
                                              }
                                              
                                              if ( weakself_.reopenTitlebarShareOverlay ) {
                                                weakself_.reopenTitlebarShareOverlay = NO;
                                                [[[Utilities del] viewController] toggleShareDrawer];
                                              }
                                              
                                              [[ContentManager shared] emptyTrash];
                                              weakself_.dirtySwipes = 0;
                                              
                                            });
                                            
                                          }];
  

  [[NSNotificationCenter defaultCenter] postNotificationName:@"single_article_finished_loading"
                                                      object:nil];
  
}

- (void)hideStalePage {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"new_webcontent_loaded"
                                                  object:nil];
}


#pragma mark - Backable
- (void)backTapped {
  
  self.currentIndex = (NSInteger)MAXFLOAT;
  [self sweep];
  
  [[ContentManager shared] popFromResizeVector];
  [[DesignManager shared] setInSingleArticle:NO];
  [[[Utilities del] globalTitleBar] pop];
  

  
  if ([[ContentManager shared] adReadyOffscreen]) {
    [[[Utilities del] masterRootController] killAdOffscreen:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }

  [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self cleanup];
  //[[FileManager shared] cleanupTemporaryFiles];
}

#pragma mark - UIPageViewController
- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
  
  NSInteger nextIndex = self.currentIndex + 1;
  if ( self.currentIndex + 1 >= [self.articles count] ) {
    nextIndex = 0;
  }
  
  if ( [[ContentManager shared] adReadyOffscreen] && !self.adNeedsDisposal ) {
    self.adContainerRight = [[SCPRDFPViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDFPViewController"]
                                                                    bundle:nil];
    self.adContainerRight.index = nextIndex;
    self.adContainerRight.delegate = self;
    [self.adContainerRight armSwipers];
    
    return self.adContainerRight;
  }
  
  return [self prepareArticleViewWithIndex:nextIndex];
  
}

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
  
  NSInteger previousIndex = self.currentIndex - 1;
  if ( self.currentIndex - 1 < 0 ) {
    previousIndex = [self.articles count]-1;
  }
  
  if ( [[ContentManager shared] adReadyOffscreen] && !self.adNeedsDisposal ) {
    self.adContainerLeft = [[SCPRDFPViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDFPViewController"]
                                                                   bundle:nil];
    self.adContainerLeft.index = previousIndex;
    self.adContainerLeft.delegate = self;
    [self.adContainerLeft armSwipers];
    
    return self.adContainerLeft;
  }
  
  return [self prepareArticleViewWithIndex:previousIndex];
  
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
  if ( [pendingViewControllers count] > 0 ) {
    
    if ( [[ContentManager shared] adReadyOffscreen] ) {
      
      id pendingId = [pendingViewControllers firstObject];
      if ( [pendingId isKindOfClass:[SCPRDFPViewController class]] ) {
        SCPRDFPViewController *adController = (SCPRDFPViewController*)pendingId;
        adController.delegate = self;
        [(SCPRDFPViewController*)pendingId loadDFPAd];
        self.adWillDisplay = YES;
      }

    }

    id<Pageable> svc = (id<Pageable>)[pendingViewControllers firstObject];
    self.preservedController = svc;
    self.pendingIndex = [svc index];
    
    self.dirtySwipes++;
    if ( self.dirtySwipes % 4 == 0 ) {
      [self sweep];
    }
    
  }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
  
  if ( !completed ) return;
  if ( self.adWillDisplay ) {
    if ( self.currentIndex < [self.preservedController index] ) {
      self.adLoadedFromLeft = YES;
    } else {
      self.adLoadedFromLeft = NO;
    }
    [[ContentManager shared] adDeliveredSuccessfully];
    self.adWillDisplay = NO;
  } else {
    self.currentIndex = self.pendingIndex;
    self.adLoadedFromLeft = NO;
    UISwipeGestureRecognizerDirection d = UISwipeGestureRecognizerDirectionRight;
    [[ContentManager shared] tickSwipe:d
                                inView:nil
                           penultimate:NO
                         silenceVector:[NSMutableArray new]];
    self.adHasBeenDismissed = NO;
  }
  
  
}

- (void)snapCurrent {
  
  UIViewController *cv = (UIViewController*)self.currentPage;
  
  NSLayoutConstraint *hc = [NSLayoutConstraint constraintWithItem:cv.view
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:self.view.frame.size.width];
  
  NSLayoutConstraint *vc = [NSLayoutConstraint constraintWithItem:cv.view
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:self.view.frame.size.height];
  
  [cv.view addConstraints:@[hc,vc]];
  
  [UIView animateWithDuration:0.33 animations:^{
    [cv.view.superview layoutIfNeeded];
    cv.view.alpha = 1.0;
  } completion:^(BOOL finished) {
    
  }];
}

#pragma mark - UIScrollViewDelegate

- (void)brandWithCategory:(ContentCategory)category {
  switch (category) {
    case ContentCategoryNews:
      [[[Utilities del] globalTitleBar] applyBackButtonText:@"News"];
      break;
    case ContentCategoryPhotoVideo:
      [[[Utilities del] globalTitleBar] applyBackButtonText:@"Photo & Video"];
      break;
    case ContentCategoryEvents:
      [[[Utilities del] globalTitleBar] applyBackButtonText:@"Live Events"];
      break;
    case ContentCategoryEditions:
    case ContentCategoryUnknown:
      [[[Utilities del] globalTitleBar] applyBackButtonText:@"Back"];
      break;
  }
}

- (void)unlockSelf {
  @synchronized(self) {
    self.contentLock = NO;
  }

  for ( SCPRSingleArticleViewController *savc in self.visualComponents ) {
    if (savc.index == self.currentIndex) {
      [savc handleDelayedLoad];
    }
  }
}

#pragma mark - Our DFP Delegate
- (void)adDidFinishLoading {
  [UIView animateWithDuration:.38 animations:^{
    self.adContainerLeft.view.alpha = 1.0;
    self.adContainerRight.view.alpha = 1.0;
  } completion:^(BOOL finished) {
    
  }];
}

- (void)armDismissal {
  /*self.dismissLeft = [[UISwipeGestureRecognizer alloc]
                      initWithTarget:self
                      action:@selector(dismissAdLeft)];
  
  self.dismissRight = [[UISwipeGestureRecognizer alloc]
                       initWithTarget:self
                       action:@selector(dismissAdRight)];
  
  self.dismissRight.direction = UISwipeGestureRecognizerDirectionRight;
  self.dismissLeft.direction = UISwipeGestureRecognizerDirectionLeft;
  
  [self.view addGestureRecognizer:self.dismissLeft];
  [self.view addGestureRecognizer:self.dismissRight];*/
}

- (void)disarmDismissal {
  /*[self.view removeGestureRecognizer:self.dismissRight];
  [self.view removeGestureRecognizer:self.dismissLeft];*/
}

- (void)dismissAdLeft {
  //[self adWillDismiss:DismissDirectionLeft];
}

- (void)dismissAdRight {
  //[self adWillDismiss:DismissDirectionRight];
}

- (void)adWillDismiss:(DismissDirection)direction {
  
  if ( self.adHasBeenDismissed ) return;
  self.adHasBeenDismissed = YES;
  
  __block SCPRSingleArticleCollectionViewController *weakself_ = self;
  NSInteger index = direction == DismissDirectionLeft ? self.currentIndex + 1 : self.currentIndex - 1;
  if ( (direction == DismissDirectionRight && self.adLoadedFromLeft) ||
       (direction == DismissDirectionLeft && !self.adLoadedFromLeft ) ) {
    index = self.currentIndex;
  }
  
  if ( index < 0 ) index = [self.articles count]+index;
  if ( index >= [self.articles count]-1 ) index = 0;
  SCPRSingleArticleViewController *sac = [self prepareArticleViewWithIndex:index];
  
  UIPageViewControllerNavigationDirection scrollDir = direction == DismissDirectionLeft ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
  
  [self.articlePageViewController setViewControllers:@[sac]
                                           direction:scrollDir
                                            animated:YES
                                          completion:^(BOOL finished) {
                                            
                                            weakself_.currentIndex = index;
                                            
                                            
                                          }];
}

- (void)adDidFail {
  [self armDismissal];
}


#pragma mark - Rotatable
- (void)handleRotationPre {
  
  // Make sure lower share modal is closed.
  if (self.currentPage) {
    SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.currentPage;
    [svc closeShareModal];
  }
  
  if ([[ContentManager shared] adReadyOffscreen]) {
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root undeliverAd];
    
    [[AnalyticsManager shared] logEvent:@"ad_was_loaded_but_avoided"
                         withParameters:@{}];
  }
  
  [UIView animateWithDuration:0.25 animations:^{
    self.articleScroller.alpha = 0.0;
  } completion:^(BOOL finished) {
    
    
  }];
}

- (NSUInteger)pageViewControllerSupportedInterfaceOrientations:(UIPageViewController *)pageViewController {
  return UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationLandscapeRight|UIInterfaceOrientationPortrait;
}

- (void)handleRotationPost {
  
  /*
  SCPRSingleArticleCollectionViewController *dummy = [[SCPRSingleArticleCollectionViewController alloc]
                                                      initWithNibName:[[DesignManager shared]
                                                                       xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                      bundle:nil];
  dummy.view.frame = dummy.view.frame;
  self.view.frame = dummy.view.frame;
  self.articleScroller.frame = dummy.articleScroller.frame;
  
  [self setupWithCollection:self.articles
           beginningAtIndex:self.currentIndex
               processIndex:YES];
  
  
  [UIView animateWithDuration:0.25 animations:^{
    self.articleScroller.alpha = 1.0;
  }];
  */
  
  [self setAdNeedsDisposal:NO];
  
  SCPRSingleArticleViewController *currentArticle = (SCPRSingleArticleViewController*)self.currentPage;
  SCPRViewController *scpr = [[Utilities del] viewController];
  if ( [scpr shareDrawerOpen] ) {
    [scpr toggleShareDrawer];
  }
  
  if ( [currentArticle isKindOfClass:[SCPRSingleArticleViewController class]] ) {
    if ( currentArticle.shareModalOpen ) {
      [currentArticle closeShareModal];
    }
  
    if ( self.currentPage ) {
      [[ContentManager shared] disposeOfObject:self.currentPage protect:YES];
    }
  }
  
  [self setupWithCollection:self.articles
           beginningAtIndex:self.currentIndex
               processIndex:YES];
  
  [self.view setNeedsLayout];
  [self.view setNeedsUpdateConstraints];
  
}

- (void)cleanup {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING ARTICLE COLLECTION VIEW CONTROLLER...");
}
#endif

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  
  // Dispose of any resources that can be recreated.
  [[ContentManager shared] emptyTrash];
}

@end
