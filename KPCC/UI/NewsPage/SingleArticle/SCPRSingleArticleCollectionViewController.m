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
  
  if ( [Utilities isIOS7] ) {
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
  }
  
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
  for ( SCPRSingleArticleViewController *article in self.untouchables ) {
    if ( abs(article.index - self.currentIndex) > 3 ) {
      [[ContentManager shared] disposeOfObject:article protect:NO];
    } else {
      [tmp addObject:article];
    }
  }
  self.untouchables = tmp;
  [[ContentManager shared] emptyTrash];
  
}

- (void)viewDidAppear:(BOOL)animated {
  [[DesignManager shared] setInSingleArticle:YES];
  [[[Utilities del] globalTitleBar] applyKpccLogo];
}

- (void)viewWillAppear:(BOOL)animated {
  /*self.articleScroller.contentSize = CGSizeMake([self.visualComponents count] * self.articleScroller.frame.size.width,
                                                self.articleScroller.frame.size.height);*/
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
  
  [self sweep];
  
  [[ContentManager shared] popFromResizeVector];
  [[DesignManager shared] setInSingleArticle:NO];
  [[[Utilities del] globalTitleBar] pop];
  
  //[[FileManager shared] cleanupTemporaryFiles];
  
  if ([[ContentManager shared] adReadyOffscreen]) {
    [[[Utilities del] masterRootController] killAdOffscreen:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }

  [self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self cleanup];
}

#pragma mark - UIPageViewController
- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
  
  NSInteger nextIndex = self.currentIndex + 1;
  if ( self.currentIndex + 1 >= [self.articles count] ) {
    nextIndex = 0;
  }

  if ( [[ContentManager shared] adReadyOffscreen] ) {
    self.adContainerRight = [[SCPRDFPViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDFPViewController"]
                                                                    bundle:nil];
    return self.adContainerRight;
  }
  
  return [self prepareArticleViewWithIndex:nextIndex];
}

- (UIViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
  NSInteger previousIndex = self.currentIndex - 1;
  if ( self.currentIndex - 1 < 0 ) {
    previousIndex = [self.articles count]-1;
  }
  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    self.adContainerLeft = [[SCPRDFPViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDFPViewController"]
                                                                   bundle:nil];
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
      }

      
    } else {
      SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)[pendingViewControllers firstObject];
      self.currentPage = svc;
      self.pendingIndex = svc.index;
      self.dirtySwipes++;
      if ( self.dirtySwipes % 3 == 0 ) {
        [self sweep];
      }
    }
    
  }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
  
    // potentially arm some dismissal gestures
    [[ContentManager shared] adDeliveredSuccessfully];
    
  } else {
  
    UISwipeGestureRecognizerDirection d = UISwipeGestureRecognizerDirectionRight;
    [[ContentManager shared] tickSwipe:d
                                inView:nil
                           penultimate:NO
                         silenceVector:[NSMutableArray new]];
    self.currentIndex = self.pendingIndex;
    [[ContentManager shared] setFocusedContentObject:self.articles[self.currentIndex]];
    
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
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  @synchronized(self) {
    self.contentLock = YES;
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  CGFloat newIndex = self.articleScroller.contentOffset.x;
  CGFloat oldIndex = self.currentOffset.x;

  // Fetch more news if we are less than 3 swipes from the end of the article stack. Don't fetch for any CollectionTypes other than News.
  if (self.category == ContentCategoryNews) {
    if ([self.articles count] - self.currentIndex <= 4 && !self.fetchLock) {
      @synchronized(self) {
        self.fetchLock = YES;
        SCPRDeluxeNewsViewController *dnc = (SCPRDeluxeNewsViewController*)self.parentDeluxeNewsPage;
        [dnc fetchArticleContent:dnc.currentNewsCategorySlug withCallback:^(BOOL finished) {
          if (finished) {
            [self setupWithCollection:dnc.monolithicNewsVector
                     beginningAtIndex:self.currentIndex
                         processIndex:YES];
            self.fetchLock = NO;
          }
        }];
      }
    }
  }
  
  UISwipeGestureRecognizerDirection direction = UISwipeGestureRecognizerDirectionLeft;
  if (newIndex > oldIndex) {
    self.currentIndex++;
    direction = UISwipeGestureRecognizerDirectionLeft;
    self.protect = @"right";
    [self setupWithCollection:self.articles
             beginningAtIndex:self.currentIndex
               processIndex:NO];
    
  } else if (newIndex < oldIndex) {
    direction = UISwipeGestureRecognizerDirectionRight;
    self.currentIndex--;
    self.protect = @"left";
    [self setupWithCollection:self.articles
             beginningAtIndex:self.currentIndex
                 processIndex:NO];
    
  }
  
  if (self.contentTimer) {
    if ([self.contentTimer isValid]) {
      [self.contentTimer invalidate];
    }
  }
  
  SCPRSingleArticleViewController *currentPage = (SCPRSingleArticleViewController*)self.currentPage;
  [currentPage snapToContentHeight];
  
  self.contentTimer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                        target:self
                                                      selector:@selector(unlockSelf)
                                                      userInfo:nil
                                                       repeats:NO];
  if (!self.collectionType) {
    self.collectionType = @"Other";
  }
  
  [self brandWithCategory:self.category];
  
  NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:currentPage.relatedArticle] mutableCopy];
  [params setObject:[NSDate stringFromDate:[NSDate date]
                        withFormat:@"MMM dd, YYYY HH:mm"]
             forKey:@"date"];
  [params setObject:self.collectionType forKey:@"accessed_from"];
  [params setObject: ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO" forKey:@"audio_on"];
  
  BOOL penultimate = NO;
  if ( direction == UISwipeGestureRecognizerDirectionLeft ) {
    penultimate = self.currentIndex == [self.articles count]-1;
  } else {
    penultimate = self.currentIndex == 0;
  }
  
  if (newIndex != oldIndex) {
    [[ContentManager shared] tickSwipe:direction
                                inView:self.articleScroller
                             penultimate:penultimate
                           silenceVector:[@[ ] mutableCopy]];
  }
  
#ifdef DEBUG
  UILabel *hud = [[[Utilities del] masterRootController] hudInformationLabel];
  [hud titleizeText:[NSString stringWithFormat:@"Offset X : %1.1f",self.articleScroller.contentOffset.x]
               bold:YES];
#endif
  
  [[AnalyticsManager shared] logEvent:@"story_read"
                       withParameters:params];
  
  
}

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
  
  /*
  NSTimer *failureTimer = [[ContentManager shared] adFailureTimer];
  if ( failureTimer ) {
    if ( [failureTimer isValid] ) {
      [failureTimer invalidate];
    }
  }
  
  [[ContentManager shared] setAdFailureTimer:nil];
  [(UIScrollView*)self.adPresentationView setScrollEnabled:YES];
  [(UIScrollView*)self.adPresentationView setClipsToBounds:YES];
  
  
  [self disarmDismissal];
  
  CGFloat xDelta = 0.0;
  if ( direction == DismissDirectionRight ) {
    xDelta = self.view.frame.size.width;
  }
  if ( direction == DismissDirectionLeft ) {
    xDelta = self.view.frame.size.width*-1.0;
  }
  
  CGPoint offset = [(UIScrollView*)self.adPresentationView contentOffset];
  xDelta = xDelta + offset.x;
  
  [UIView animateWithDuration:.38 animations:^{
    self.dfpAdViewController.view.frame = CGRectMake(xDelta, 0.0,self.dfpAdViewController.view.frame.size.width,
                                                     self.dfpAdViewController.view.frame.size.height);
    
    
    for ( UIView *v in [self adSilenceVector] ) {
      v.alpha = 1.0;
    }
    
  } completion:^(BOOL finished) {
    
    self.adSilenceVector = nil;
    [self.dfpAdViewController.view removeFromSuperview];
    self.dfpAdViewController = nil;
    [[ContentManager shared] setAdIsDisplayingOnScreen:NO];
    
  }];
  */
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
  
  if ( self.currentPage ) {
    [[ContentManager shared] disposeOfObject:self.currentPage protect:YES];
  }
  
  [self setupWithCollection:self.articles
           beginningAtIndex:self.currentIndex
               processIndex:YES];
  
  [self.view setNeedsLayout];
  [self.view setNeedsUpdateConstraints];
  
}

- (void)cleanup {
  /*
  for (SCPRSingleArticleViewController *svc in self.visualComponents) {
    [svc killContent];
  }
  
  for (SCPRSingleArticleViewController *svc in [self.wingArticles allValues]) {
    [svc killContent];
  }
  
  [self.queuedForTrash removeAllObjects];
  [self.visualComponents removeAllObjects];
  [self.wingArticles removeAllObjects];
  
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
  
  [[ContentManager shared] printCacheUsage];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  if (self.parentDeluxeNewsPage) {
    SCPRDeluxeNewsViewController *dnc = (SCPRDeluxeNewsViewController*)self.parentDeluxeNewsPage;
    dnc.pushedCollection = nil;
  }*/
  
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
