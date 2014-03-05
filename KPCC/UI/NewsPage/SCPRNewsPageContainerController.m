//
//  SCPRNewsPageContainerController.m
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRNewsPageContainerController.h"
#import "SCPRNewsPageViewController.h"
#import "SCPRSingleArticleCollectionViewController.h"
#import "global.h"
#import "SCPRFlapViewController.h"

#define kAdjustUIOnScrollThreshold 30.0

@interface SCPRNewsPageContainerController ()

@end

@implementation SCPRNewsPageContainerController

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
    // Do any additional setup after loading the view from its nib.
  self.bannerAdView.alpha = 0.0;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(scrollViewScrolled:)
                                               name:@"main_scroller_scrolled"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trashNav)
                                               name:@"garbage_collect_navigation"
                                             object:nil];
  
  self.shadowView = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,self.view.frame.size.width,
                                                             self.view.frame.size.height)];
  self.shadowView.backgroundColor = [[DesignManager shared] obsidianColor:0.88];
  self.shadowView.alpha = 0.0;
  [self.view addSubview:self.shadowView];
  
  self.ghostFrame = self.view.frame;
}

- (void)viewDidAppear:(BOOL)animated {
  if ( self.trashNavigation ) {
    self.trashNavigation = NO;
    [self trashNav];
  }
}

- (void)unplug {
  [self detach];
}

- (void)detach {
  self.designatedNav = nil;
  self.child = nil;
  self.observableScroller = nil;
}

- (void)trashNav {
  
  SCPRNewsPageViewController *npc = (SCPRNewsPageViewController*)self.child;
  SCPRSingleArticleCollectionViewController *collection = npc.pushed;
  if ( collection ) {
    NSLog(@"Collection still in play..");
    [collection cleanup];
    npc.pushed = nil;
  }
  
  //[[NSURLCache sharedURLCache] removeAllCachedResponses];
  [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  NSLog(@"ViewControllers : %d",self.designatedNav.viewControllers.count);
  
  id toplevel = [self.designatedNav topViewController];
  NSLog(@"Top level is kind of : %@",[toplevel class]);
  
}

- (void)setObservableScroller:(UIScrollView *)observableScroller {
  if ( self.observableScroller && observableScroller != nil ) {
    return;
  }
  
  if ( _observableScroller && !observableScroller ) {
    [_observableScroller removeObserver:self
                             forKeyPath:@"contentOffset"];
  }
  
  _observableScroller = observableScroller;
  
  if ( observableScroller ) {
    [self.observableScroller addObserver:self
                              forKeyPath:@"contentOffset"
                                 options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                 context:nil];
  }
  

}

- (void)scrollViewScrolled:(NSNotification*)note {
  
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( object == self.observableScroller ) {
    /*
    CGPoint raw = self.view.frame.origin;
    UIView *navView = self.observableScroller;
    CGPoint cooked = [navView convertPoint:raw
                                      fromView:self.view];
    
    NSLog(@"ContentOffset x : %1.1f against my origin x : %1.1f",self.observableScroller.contentOffset.x,
          cooked.x);
    CGPoint offset = [[change objectForKey:@"new"] CGPointValue];
    if ( offset.x+kAdjustUIOnScrollThreshold >= self.view.frame.origin.x ||
          offset.x-kAdjustUIOnScrollThreshold <= self.view.frame.origin.x ) {
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationDuration:0.25];
      self.pageTitleLabel.alpha = 1.0;
      [UIView commitAnimations];
    } else {
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationDuration:0.25];
      self.pageTitleLabel.alpha = 1.0;
      [UIView commitAnimations];
    }*/
    [[DesignManager shared] turn:self
                      withValues:change];
  }
}

- (void)appendContent {
  
  NSMutableArray *newContent = [self.contentDelegate mediaContentForTopic:self.topicSlug];
  NSInteger offset = [self.newsPages count];

  NSInteger ceil = ceilf([newContent count]/[self.contentDelegate numberOfStoriesPerPage]);

  CGFloat newsHeight = 0.0;
  for ( unsigned i = 0; i < ceil; i++ ) {
    SCPRNewsPageViewController *newsPage = nil;
    BOOL newPage = NO;
    if ( i < offset ) {
      newsPage = [self.newsPages objectAtIndex:i];
    } else {
      newsPage = [[SCPRNewsPageViewController alloc] initWithNibName:[[DesignManager shared]
                                                                                                xibit:@"SCPRNewsPageViewController"
                                                                                                style:(i % 2)]
                                                                                      bundle:nil];
      newPage = YES;
    }
    newsPage.view.frame = CGRectMake(0.0,0.0,
                                     newsPage.view.frame.size.width,
                                     newsPage.view.frame.size.height);
    newsPage.contentDelegate = self.contentDelegate;
    newsPage.pageIndex = i;
    newsPage.topicTitleCode = [NSString stringWithFormat:@"Home-%d",i];
    newsPage.templateType = (i % 2);
    //newsPage.view.alpha = 0.0;
    newsPage.topicSlug = self.topicSlug;
    newsPage.parentContainer = self;
    newsHeight = newsPage.view.frame.size.height;
    CGRect containerFrame = CGRectMake(0.0,(i*newsPage.view.frame.size.height),
                                       newsPage.view.frame.size.width,
                                       newsPage.view.frame.size.height);
    
    
    newsPage.view.frame = containerFrame;
    
    if ( newPage ) {
      [self.contentScroller addSubview:newsPage.view];
      [newsPage activatePage];
    } else {
      newsPage.activated = NO;
      [newsPage activatePage];
    }
  
    if ( newPage ) {
      [self.newsPages addObject:newsPage];
    }
  }
  
  
  self.contentScroller.contentSize = CGSizeMake(self.contentScroller.contentSize.width,
                                                [self.newsPages count]*newsHeight);
}

#pragma mark - Turnable

- (NSInteger)ghostIndex {
  return self.pageIndex;
}

- (SCPRFlapViewController*)leftFlap {
  return nil;
}

- (SCPRFlapViewController*)rightFlap {
  return nil;
}

- (UIView*)bendableView {
  return self.view;
}

- (BOOL)shouldAutorotate {
  return [[DesignManager shared] inSingleArticle];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)dealloc {
  self.child = nil;
  //NSLog(@"Adios from News Page Collection!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
