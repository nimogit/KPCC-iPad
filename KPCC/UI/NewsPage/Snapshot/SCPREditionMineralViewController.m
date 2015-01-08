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
  
  [[[Utilities del] globalTitleBar] applyClearBackground];
  
    // Do any additional setup after loading the view from its nib.
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
  for ( SCPREditionCrystalViewController *snap in self.contentVector ) {
    [snap.view removeFromSuperview];
    needsRefresh = YES;
  }
  
  [self.contentVector removeAllObjects];
  
  CGFloat widthToUse = self.editionsScroller.bounds.size.width;
  CGFloat heightToUse = self.editionsScroller.bounds.size.height;
  
  if ( needsRefresh ) {
    SCPREditionMineralViewController *emvD = [[SCPREditionMineralViewController alloc]
                                              initWithNibName:[[DesignManager shared]
                                                               xibForPlatformWithName:@"SCPREditionMineralViewController"]
                                              bundle:nil];
    emvD.view.frame = emvD.view.frame;
    widthToUse = emvD.editionsScroller.frame.size.width;
    heightToUse = emvD.editionsScroller.frame.size.height;
    CGRect r = emvD.editionsScroller.frame;
    self.editionsScroller.frame = r;
  }
  

  self.contentVector = [[NSMutableArray alloc] init];
  
  //NSInteger limit = kEditionsTotal;
  //self.editions = [self.editions subarrayWithRange:NSMakeRange(0, limit)];
  
  NSInteger processingIndex = -1;
  for ( unsigned i = 0; i < [self.editions count]; i++ ) {
    
    NSMutableDictionary *edition = [self.editions objectAtIndex:i];
    SCPREditionShortListViewController *snap = nil;

    snap = [[SCPREditionShortListViewController alloc] initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPREditionShortListViewController"]
                                                         bundle:nil];
  
    snap.edition = edition;

    
    CGFloat adjuster = [Utilities isIOS7] ? 0.0 : 0.0;
    CGRect eFrame = CGRectMake(i*widthToUse,
                               0.0,
                               widthToUse,
                               heightToUse-adjuster);
    snap.view.frame = eFrame;
    snap.parentMineral = self;
    [snap setupWithEdition:snap.edition];
    
    contentHeight = snap.view.frame.size.height;
    
    [self.editionsScroller addSubview:snap.view];
    [self.contentVector addObject:snap];
    
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
  
  self.targetMolecule = nil;
  self.editionsScroller.contentSize = CGSizeMake([self.editions count]*self.editionsScroller.frame.size.width,
                                                 self.editionsScroller.frame.size.height);
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    //[[NetworkManager shared] fetchContentForEditionals:self];
  });
  
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
  /*
  [self setupWithEditions:self.editions];
  self.editionsScroller.contentOffset = CGPointMake(self.editionsScroller.frame.size.width*self.currentIndex,
                                                    0.0);
  
  [UIView animateWithDuration:0.25 animations:^{
    self.editionsScroller.alpha = 1.0;
  }];*/
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
