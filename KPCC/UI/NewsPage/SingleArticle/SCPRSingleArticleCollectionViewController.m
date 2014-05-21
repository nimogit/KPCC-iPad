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
  
  self.view.backgroundColor = [[DesignManager shared] vinylColor:1.0];
  self.articleScroller.pagingEnabled = YES;
  self.articleScroller.showsHorizontalScrollIndicator = NO;
  self.articleScroller.showsVerticalScrollIndicator = NO;
  self.contentLock = NO;
  self.fetchLock = NO;
  self.wingArticles = [[NSMutableDictionary alloc] init];
  self.articles = [[NSMutableArray alloc] init];
  self.visualComponents = [[NSMutableArray alloc] init];
  self.queuedForTrash = [[NSMutableDictionary alloc] init];
  self.webcontentQueue = [[NSOperationQueue alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
  [[DesignManager shared] setInSingleArticle:YES];
  [[[Utilities del] globalTitleBar] applyKpccLogo];
}

- (void)viewWillAppear:(BOOL)animated {
  self.articleScroller.contentSize = CGSizeMake([self.visualComponents count] * self.articleScroller.frame.size.width,
                                                self.articleScroller.frame.size.height);
}

- (void)viewDidDisappear:(BOOL)animated {
  if ( self.trash ) {
    self.trash = NO;
  }
}

- (void)setupWithCollection:(NSArray *)articles beginningAtIndex:(NSInteger)index processIndex:(BOOL)processIndex {
  
  if ( index == [articles count]-1 ) {
    NSLog(@"Final article...");
  }
  
  if ( index >= [articles count] ) {
    return;
  }
  
  if ( self.currentPage ) {
    SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.currentPage;
    [svc killContent];
  }
  
  if ( index != [articles count]-1 ) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hideStalePage)
                                               name:@"new_webcontent_loaded"
                                             object:nil];
  }
  
  self.articles = [NSMutableArray arrayWithArray:articles];
  self.currentIndex = index;

  
  for ( NSString *key in [self.wingArticles allKeys] ) {
    if ( [key isEqualToString:self.protect] ) {
      SCPRSingleArticleViewController *svc = [self.wingArticles objectForKey:key];
      svc.workerThread = NO;
      continue;
    }
    
    SCPRSingleArticleViewController *svc = [self.wingArticles objectForKey:key];
    [svc killContent];
    [self.wingArticles removeObjectForKey:key];
  }
  
  NSDictionary *relatedArticle = [articles objectAtIndex:index];
  
  SCPRSingleArticleViewController *articleView = nil;

  
  if ( !processIndex ) {
    articleView = [self.wingArticles objectForKey:self.protect];
    articleView.observableScroller = nil;
  } else {
    articleView = [[SCPRSingleArticleViewController alloc]
                   initWithNibName:[[DesignManager shared]
                    xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                    bundle:nil];
  }
  
  if ( !articleView ) {
    articleView = [[SCPRSingleArticleViewController alloc]
                   initWithNibName:[[DesignManager shared]
                                    xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                   bundle:nil];
  }
  
  articleView.index = index;
  self.currentPage = articleView;

  
  articleView.relatedArticle = relatedArticle;
  [[ContentManager shared] setFocusedContentObject:relatedArticle];
  
  CGFloat widthToUse = self.articleScroller.frame.size.width;
  CGFloat heightToUse = self.articleScroller.frame.size.height;
  BOOL needsRefresh = NO;
  if ( UIDeviceOrientationIsLandscape(self.interfaceOrientation) ) {
    if ( widthToUse < heightToUse ) {
      needsRefresh = YES;
    }
  }
  if ( UIDeviceOrientationIsPortrait(self.interfaceOrientation) ) {
    if ( heightToUse < widthToUse ) {
      needsRefresh = YES;
    }
  }
  
  if ( needsRefresh ) {
    SCPRSingleArticleCollectionViewController *cd = [[SCPRSingleArticleCollectionViewController alloc]
                                                     initWithNibName:[[DesignManager shared]
                                                                      xibForPlatformWithName:@"SCPRSingleArticleCollectionViewController"]
                                                     bundle:nil];
    cd.view.frame = cd.view.frame;
    widthToUse = cd.articleScroller.frame.size.width;
    heightToUse = cd.articleScroller.frame.size.height;
    self.articleScroller.frame = cd.articleScroller.frame;
  }
  
  if ( index == 0 || index == [articles count]-1 ) {
    if ( [articles count] == 1 ) {
      self.articleScroller.contentSize = CGSizeMake(widthToUse,
                                                  heightToUse);
    } else {
      self.articleScroller.contentSize = CGSizeMake(2*widthToUse,
                                                    heightToUse);
    }
  } else {
    self.articleScroller.contentSize = CGSizeMake(3*widthToUse,
                                                  heightToUse);
  }

  
  CGFloat xOrigin = index == 0 ? 0.0 : widthToUse;
  BOOL limitLeft = index == 0 ? YES : NO;
  
  CGFloat yDelta = [Utilities isIOS7] ? 0.0 : 20.0;
  
  CGRect rFrame = CGRectMake(xOrigin,yDelta,
                                      widthToUse,
                                      heightToUse);
  articleView.view.frame = rFrame;
  articleView.parentCollection = self;
  articleView.webContentLoader.loadingSkeletonContent = NO;
  
  [articleView arrangeContent];
  
  articleView.ghostIndex = limitLeft ? 0 : 1;
  if ( processIndex ) {
    [self.articleScroller addSubview:articleView.view];
  }

  SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.currentPage;
  if ( svc ) {
    [self.articleScroller bringSubviewToFront:svc.view];
  }
  
  
  if ( !self.visualComponents ) {
    NSMutableArray *newVisual = [[NSMutableArray alloc] init];
    self.visualComponents = newVisual;
  } else {
    [self.visualComponents removeAllObjects];
  }
  

  [self.visualComponents addObject:articleView];
  
  if ( self.protect ) {
    [self.wingArticles removeObjectForKey:self.protect];
    self.protect = @"";
  }
  
  articleView.parentNewsPage = self.parentContainer;
  
  //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSInteger pages = 1;
    if ( index != 0 && [articles count] > 1 ) {
      
      NSDictionary *leftArticle = [articles objectAtIndex:index-1];
      
      SCPRSingleArticleViewController *leftArticleView = [[SCPRSingleArticleViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleViewController"] bundle:nil];
   
      leftArticleView.index = index-1;
      leftArticleView.relatedArticle = leftArticle;
      leftArticleView.view.frame = CGRectMake(0.0,yDelta,
                                              widthToUse,
                                              heightToUse);
      leftArticleView.parentNewsPage = self.parentContainer;
      leftArticleView.parentCollection = self;
      leftArticleView.webContentLoader.loadingSkeletonContent = YES;
      [leftArticleView arrangeContent];
      
      leftArticleView.ghostIndex = 0;
      
      [self.articleScroller addSubview:leftArticleView.view];
      
      if ( [self.wingArticles objectForKey:@"left"] ) {
        SCPRSingleArticleViewController *oldLeft = [self.wingArticles objectForKey:@"left"];
        [oldLeft killContent];
      }
      
      [self.wingArticles setObject:leftArticleView
                            forKey:@"left"];
      pages++;
      
      self.waitingForLoad++;
      [self.visualComponents addObject:leftArticleView];
      
    }
    if ( index != [articles count]-1 && [articles count] > 1 ) {
      
      NSDictionary *rightArticle = [articles objectAtIndex:index+1];
      
      SCPRSingleArticleViewController *rightArticleView = [[SCPRSingleArticleViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRSingleArticleViewController"]
                                                                                                            bundle:nil];

      rightArticleView.index = index+1;
      rightArticleView.relatedArticle = rightArticle;
      rightArticleView.view.frame = CGRectMake(xOrigin+widthToUse,yDelta,
                                               widthToUse,
                                               heightToUse);
  
      rightArticleView.webContentLoader.loadingSkeletonContent = YES;
      rightArticleView.parentNewsPage = self.parentContainer;
      rightArticleView.parentCollection = self;
      [rightArticleView arrangeContent];
      
      rightArticleView.ghostIndex = limitLeft ? 1 : 2;
      
      [self.articleScroller addSubview:rightArticleView.view];
      
      if ( [self.wingArticles objectForKey:@"right"] ) {
        SCPRSingleArticleViewController *oldRight = [self.wingArticles objectForKey:@"right"];
        [oldRight killContent];
        //[oldRight.view removeFromSuperview];
        
      }
      
      [self.wingArticles setObject:rightArticleView
                            forKey:@"right"];
      pages++;
      self.waitingForLoad++;
      [self.visualComponents addObject:rightArticleView];
    }
  

  
  self.articleScroller.contentOffset = CGPointMake(xOrigin,
                                                     0.0);
  self.articleScroller.delegate = self;
  self.currentOffset = self.articleScroller.contentOffset;

  if ( self.articleScroller ) {
    self.articleScroller.contentSize = CGSizeMake([self.visualComponents count]*self.articleScroller.frame.size.width,
                                                  self.articleScroller.frame.size.height);
  }
  
#ifdef ENABLE_ADS
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  [root preserveAd];
#endif
  
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

  if ( ![Utilities isIOS7] ) {
    SCPRViewController *mvc = [[Utilities del] viewController];
    [mvc.mainPageScroller setContentOffset:CGPointMake(0.0, 0.0)];
  }
  
  //SCPRDeluxeNewsViewController *dnc = (SCPRDeluxeNewsViewController*)self.parentDeluxeNewsPage;
  //dnc.armToKill = YES;
  
  [[ContentManager shared] popFromResizeVector];
  [[DesignManager shared] setInSingleArticle:NO];
  [[[Utilities del] globalTitleBar] pop];
  
  [[FileManager shared] cleanupTemporaryFiles];
  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    [[[Utilities del] masterRootController] killAdOffscreen:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }

  [self cleanup];
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
  if ( newIndex > oldIndex ) {
    self.currentIndex++;
    direction = UISwipeGestureRecognizerDirectionLeft;
    self.protect = @"right";
    [self setupWithCollection:self.articles
             beginningAtIndex:self.currentIndex
               processIndex:NO];
    
  } else if ( newIndex < oldIndex ) {
    
    direction = UISwipeGestureRecognizerDirectionRight;
    self.currentIndex--;
    self.protect = @"left";
    [self setupWithCollection:self.articles
             beginningAtIndex:self.currentIndex
                 processIndex:NO];
    
  }
  
  if ( self.contentTimer ) {
    if ( [self.contentTimer isValid] ) {
      [self.contentTimer invalidate];
    }
  }
  
  SCPRSingleArticleViewController *currentPage = (SCPRSingleArticleViewController*)self.currentPage;
  [currentPage snapToContentHeight];
  [currentPage arm];
  
  self.contentTimer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                        target:self
                                                      selector:@selector(unlockSelf)
                                                      userInfo:nil
                                                       repeats:NO];
  if ( !self.collectionType ) {
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
  
  //UIView *playerBar = [[[Utilities del] globalPlayer] view];
  
  if ( newIndex != oldIndex ) {
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
    if ( savc.index == self.currentIndex ) {
      [savc handleDelayedLoad];
    }
    [savc handleMultipleAssets];
  }
}


#pragma mark - Rotatable
- (void)handleRotationPre {
  
  // Make sure lower share modal is closed.
  if ( self.currentPage ) {
    SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.currentPage;
    [svc closeShareModal];
  }
  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
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

- (void)handleRotationPost {
  
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
  
}

- (void)cleanup {
  
  for ( SCPRSingleArticleViewController *svc in self.visualComponents ) {
    [svc killContent];
  }
  
  for ( SCPRSingleArticleViewController *svc in [self.wingArticles allValues] ) {
    [svc killContent];
  }
  
  [self.queuedForTrash removeAllObjects];
  [self.visualComponents removeAllObjects];
  [self.wingArticles removeAllObjects];
  
  [[NSURLCache sharedURLCache] removeAllCachedResponses];
  
  [[ContentManager shared] printCacheUsage];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  if ( self.parentDeluxeNewsPage ) {
    SCPRDeluxeNewsViewController *dnc = (SCPRDeluxeNewsViewController*)self.parentDeluxeNewsPage;
    dnc.pushedCollection = nil;
  }
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  
  NSLog(@"DEALLOCATING ARTICLE COLLECTION VIEW CONTROLLER...");
  
}
#endif

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  
  // Dispose of any resources that can be recreated.
  [self.queuedForTrash removeAllObjects];
}

@end
