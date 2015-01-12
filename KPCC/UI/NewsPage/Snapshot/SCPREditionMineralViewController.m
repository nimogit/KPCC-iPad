//
//  SCPREditionMineralViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionMineralViewController.h"
#import "SCPREditionCrystalViewController.h"
#import "SCPRTitlebarViewController.h"
#import "SCPREditionMoleculeViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPREditionShortListViewController.h"

@interface SCPREditionMineralViewController ()

@end

@implementation SCPREditionMineralViewController

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
  
  self.currentIndex = 0;
  self.editionsScroller.pagingEnabled = YES;
  [[[Utilities del] globalTitleBar] applyClearBackground];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews {
  if ( self.needsSnap ) {
    self.needsSnap = NO;
    [self snapContent];
  }
}

- (void)snapContent {
  
  if ( !self.setupCompleted ) {
    [self setupWithEditions:self.editions];
  }
  
  self.editionsScroller.contentSize = CGSizeMake([self.editions count]*self.editionsScroller.frame.size.width,
                                                 self.editionsScroller.frame.size.height);
  self.editionsScroller.contentOffset = CGPointMake(self.currentIndex*self.editionsScroller.frame.size.width,
                                                    0.0);
  [self.editionsScroller setNeedsLayout];
  
  for ( NSDictionary *metrics in [self.metricChain allValues] ) {
    NSLayoutConstraint *w = metrics[@"width"];
    [w setConstant:self.editionsScroller.frame.size.width];
    
    NSLayoutConstraint *h = metrics[@"height"];
    [h setConstant:self.editionsScroller.frame.size.height];
  }
  
  
}

- (void)setupWithEditions:(NSArray *)editions {

  
  [[AnalyticsManager shared] tS];
  [self.view setNeedsLayout];
 
  self.editionsScroller.delegate = self;
  self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
  self.editions = editions;
  
  CGFloat contentHeight = self.editionsScroller.frame.size.height;
  if ( [Utilities isIOS7] ) {
    self.automaticallyAdjustsScrollViewInsets = NO;
  } else {
    
  }
  
  BOOL needsRefresh = NO;
  for ( SCPREditionShortListViewController *snap in self.contentVector ) {
    [snap.view removeFromSuperview];
    needsRefresh = YES;
  }
  
  [self.contentVector removeAllObjects];

  
  self.contentVector = [[NSMutableArray alloc] init];
  [self.editionsScroller setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSInteger processingIndex = -1;
  SCPREditionShortListViewController *prev = nil;
  for ( unsigned i = 0; i < [self.editions count]; i++ ) {
    
    NSMutableDictionary *edition = [self.editions objectAtIndex:i];
    SCPREditionShortListViewController *snap = nil;

    snap = [[SCPREditionShortListViewController alloc] initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPREditionShortListViewController"]
                                                         bundle:nil];
  
    snap.edition = edition;
    snap.view.frame = snap.view.frame;
    snap.view.frame = CGRectMake(0.0,0.0,self.editionsScroller.frame.size.width,
                                 self.editionsScroller.frame.size.height);
    
    snap.parentMineral = self;
    [snap setupWithEdition:snap.edition];
    [snap.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [snap.view layoutIfNeeded];
    [snap.view printDimensionsWithIdentifier:@"SHORT LIST INDIVIDUAL"];
    
    contentHeight = snap.view.frame.size.height;
    
    [self.editionsScroller addSubview:snap.view];
    [self.contentVector addObject:snap];
    
    if ( prev ) {
      NSArray *hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[prev][me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"prev" : prev.view,
                                                                             @"me" : snap.view }];
      if ( i == [self.editions count]-1 ) {
        hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[prev][me]|"
                                                           options:0
                                                           metrics:nil
                                                             views:@{ @"prev" : prev.view,
                                                                      @"me" : snap.view }];
      }

      NSArray *vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : snap.view }];
      
      [self.editionsScroller addConstraints:hAnchors];
      [self.editionsScroller addConstraints:vAnchors];
      
    } else {
      
      NSArray *hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : snap.view }];
      NSArray *vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : snap.view }];
      
      [self.editionsScroller addConstraints:hAnchors];
      [self.editionsScroller addConstraints:vAnchors];
      
    }
    
    prev = snap;
    
    self.metricChain = [NSMutableDictionary new];
    NSLayoutConstraint *wC = [NSLayoutConstraint constraintWithItem:snap.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.editionsScroller.frame.size.width];
    
    
    NSLayoutConstraint *hC = [NSLayoutConstraint constraintWithItem:snap.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.editionsScroller.frame.size.height];
    
    NSDictionary *metrics = @{ @"width" : wC,
                               @"height" : hC };
    
    [self.metricChain setObject:metrics
                         forKey:@(i)];
    
    [snap.view addConstraints:@[wC,hC]];
    
    if ( self.targetMolecule ) {
      if ( i == self.currentIndex ) {
        processingIndex = i;
      }
    }
  }
  
  if ( processingIndex >= 0 ) {
    SCPREditionShortListViewController *snap = [self.contentVector objectAtIndex:processingIndex];
    SCPREditionMoleculeViewController *tMolecule = (SCPREditionMoleculeViewController*)self.targetMolecule;
    [snap pushToMolecule:tMolecule.currentIndex];
  }
  
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  [tb applyKpccLogo];
  
  
  [[ContentManager shared].settings setEditionsJson:[self.editions JSONRepresentation]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  if ( [Utilities isIpad] ) {
    if ( !self.moleculePushed ) {
      [tb applyPagerWithCount:[self.editions count]
                  currentPage:self.currentIndex];
    }
  } else {
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(10.0, 90.0, 300.0,
                                                                       21.0)];
    self.pageControl.numberOfPages = [self.editions count];
    self.pageControl.userInteractionEnabled = NO;
    self.pageControl.currentPage = self.currentIndex;
    [self.view addSubview:self.pageControl];
  }
  
  [self.editionsScroller layoutIfNeeded];
  
  self.targetMolecule = nil;

  [self.editionsScroller printDimensionsWithIdentifier:@"Editions Scroller Dimensions"];
  
  self.setupCompleted = YES;
  
  [[AnalyticsManager shared] tF:@"Building edition mineral..."];
}

- (void)viewWillAppear:(BOOL)animated {
/*  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  root.globalGradient.alpha = 1.0;
  if ( self.needsRotation ) {
    [self setupWithEditions:self.editions];
    [UIView animateWithDuration:0.22 animations:^{
      
      self.editionsScroller.alpha = 1.0;

      
    } completion:^(BOOL finished) {
      self.needsRotation = NO;
    }];
  }
 */
}

- (void)viewDidAppear:(BOOL)animated {
 /*
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  [tb applyEditionsLabel];
  SCPRTitlebarViewController *titleBar = [[Utilities del] globalTitleBar];
  [titleBar applyPagerWithCount:[self.editions count]
                    currentPage:self.currentIndex];
  if ( ![Utilities isIOS7] ) {
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y-20.0,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height+20.0);
  }
  
  
  self.editionsScroller.contentSize = CGSizeMake([self.editions count]*self.editionsScroller.frame.size.width,
                                                 self.editionsScroller.frame.size.height);
  
  */
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  [tb applyKpccLogo];
  
}

- (void)viewWillDisappear:(BOOL)animated {
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  root.globalGradient.alpha = 0.0;
}

- (void)unplug {
  
  [self.navigationController popToRootViewControllerAnimated:YES];

#ifdef AGGRESSIVE_DEALLOCATION
  for ( SCPREditionShortListViewController *esl in self.contentVector ) {
    esl.leadAssetImage.image = nil;
    [esl.leadAssetImage removeFromSuperview];
  }
#endif
  
  [self.contentVector removeAllObjects];

}

#pragma mark - Content Proc
- (void)handleEditionals:(NSArray *)editionals {
  
  NSMutableArray *complete = [self.editions mutableCopy];
  CGFloat widthToUse = self.editionsScroller.bounds.size.width;
  CGFloat heightToUse = self.editionsScroller.bounds.size.height;

  
  for ( unsigned i = 0; i < [editionals count]; i++ ) {
    
    NSMutableDictionary *edition = [self.editions objectAtIndex:i];
    SCPREditionShortListViewController *snap = nil;
    
    snap = [[SCPREditionShortListViewController alloc] initWithNibName:[[DesignManager shared]
                                                                        xibForPlatformWithName:@"SCPREditionShortListViewController"]
                                                                bundle:nil];
    
    snap.edition = edition;
    snap.parentMineral = self;
    
    CGFloat adjuster = [Utilities isIOS7] ? 0.0 : 0.0;
    CGRect eFrame = CGRectMake((i+[self.editions count])*widthToUse,
                               adjuster,
                               widthToUse,
                               heightToUse-adjuster);
    snap.view.frame = eFrame;
    
    [snap setupWithEdition:snap.edition];
    
    [self.editionsScroller addSubview:snap.view];
    [self.contentVector addObject:snap];
    [complete addObject:edition];

  }
  
  SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
  [tb applyKpccLogo];
  
  self.editions = [NSArray arrayWithArray:complete];
  
  [[ContentManager shared].settings setEditionsJson:[self.editions JSONRepresentation]];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  if ( !self.moleculePushed ) {
    [tb applyPagerWithCount:[self.editions count]
                    currentPage:self.currentIndex];
  }
  
  self.editionsScroller.contentSize = CGSizeMake([self.editions count]*self.editionsScroller.frame.size.width,
                                                 self.editionsScroller.frame.size.height);

  
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  
  [UIView animateWithDuration:0.25 animations:^{
    self.editionsScroller.alpha = 0.0;
  } completion:^(BOOL finished) {
    //[self.navigationController popToRootViewControllerAnimated:NO];
  }];
}

- (void)handleRotationPost {
  [self setSetupCompleted:NO];
  [self setNeedsSnap:YES];
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}


- (BOOL)shouldAutomaticallyForwardRotationMethods {
  return YES;
}

#pragma mark - UIScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSInteger index = (NSInteger)floorf(self.editionsScroller.contentOffset.x/self.editionsScroller.frame.size.width);
  
  if ( [Utilities isIpad] ) {
    SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
    tb.pager.currentPage = index;
  } else {
    self.pageControl.currentPage = index;
  }
  
  self.currentIndex = index;
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  [[ContentManager shared] printCacheUsage];
  NSLog(@"DEALLOCATING EDITION MINERAL...");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
