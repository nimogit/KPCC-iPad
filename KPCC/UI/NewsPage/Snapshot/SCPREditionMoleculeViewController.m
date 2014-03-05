//
//  SCPREditionMoleculeViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREditionMoleculeViewController.h"
#import "SCPREditionAtomViewController.h"
#import "SCPRTitlebarViewController.h"
#import "SCPREditionCrystalViewController.h"
#import "SCPRMasterRootViewController.h"

@interface SCPREditionMoleculeViewController ()

@end

@implementation SCPREditionMoleculeViewController

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
  
  if ( [Utilities isIOS7] ) {
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
  }
  
  self.scroller.pagingEnabled = YES;
  self.scroller.delegate = self;
  
  if ( ![Utilities isIOS7] ) {
    if ( self.fromNewsPage ) {
      self.scroller.center = CGPointMake(self.scroller.center.x,
                                         self.scroller.center.y-20.0);
    }
  }
  
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  root.adSilenceVector = [@[ self.editionInfoLabel ] mutableCopy];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  

}

- (void)viewWillAppear:(BOOL)animated {
  self.scroller.contentSize = CGSizeMake([self.editions count]*self.scroller.frame.size.width,
                                         self.scroller.frame.size.height);
  
  SCPRViewController *vc = [[Utilities del] viewController];
  vc.globalGradient.alpha = 1.0;
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupWithEdition:(NSDictionary *)edition andIndex:(NSInteger)index {
  NSArray *abstracts = [edition objectForKey:@"abstracts"];
  self.editionShell = edition;
  [self setupWithEditions:[abstracts mutableCopy] andIndex:index];
  
  NSString *abstractCount = [NSString stringWithFormat:@"%d",(int)[abstracts count]];
  [[AnalyticsManager shared] logEvent:@"edition_read"
                       withParameters:@{ @"edition_id" : [edition objectForKey:@"id"],
                                         @"edition_published_date" : [edition objectForKey:@"published_at"],
                                         @"title" : [edition objectForKey:@"title"],
                                         @"abstract_count" : abstractCount,
                                         @"audio_on" : ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO"}];
}

- (void)setupWithEditions:(NSMutableArray *)editions andIndex:(NSInteger)index {
  
  NSString *pa = [self.editionShell objectForKey:@"published_at"];
  NSDate *published = [Utilities dateFromRFCString:pa];
  NSString *timeString = [NSDate stringFromDate:published
                                     withFormat:@"EEEE, ha"];
  NSString *full = [NSString stringWithFormat:@"THE SHORT LIST: %@",[timeString uppercaseString]];
  [self.editionInfoLabel titleizeText:full bold:NO];
  self.editionInfoLabel.alpha = 1.0;
  
  if ( [Utilities isIpad] ) {
    self.editionInfoLabel.frame = CGRectMake(self.editionInfoLabel.frame.origin.x,
                                             60.0,
                                             self.editionInfoLabel.frame.size.width,
                                             self.editionInfoLabel.frame.size.height);
  }
  
  self.editions = editions;
  
  BOOL needsRefresh = NO;
  for ( SCPREditionAtomViewController *atom in self.displayVector ) {
    needsRefresh = YES;
    [atom.view removeFromSuperview];
  }
  

  
  [self.displayVector removeAllObjects];
  self.displayVector = [[NSMutableArray alloc] init];

  
  self.currentIndex = index;
  
  CGFloat widthToUse = self.scroller.frame.size.width;
  CGFloat heightToUse = self.scroller.frame.size.height;
  
  if ( needsRefresh ) {
    SCPREditionMoleculeViewController *emvc = [[SCPREditionMoleculeViewController alloc]
                                               initWithNibName:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPREditionMoleculeViewController"]
                                               bundle:nil];
    emvc.view = emvc.view;
    widthToUse = emvc.scroller.frame.size.width;
    heightToUse = emvc.scroller.frame.size.height;
    self.scroller.frame = emvc.scroller.frame;
    
  }
  
  if ( ![Utilities isIOS7] ) {
    //self.scroller.frame = CGRectMake(0.0,-20.0,self.scroller.frame.size.width,self.scroller.frame.size.height);
  }
  
  SCPREditionAtomViewController *atomDummy = [[SCPREditionAtomViewController alloc]
                                         initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPREditionAtomViewController"]
                                         bundle:nil];
  atomDummy.view.frame = atomDummy.view.frame;
  
  CGSize s = CGSizeMake([editions count]*widthToUse,
                                         heightToUse);
  
  self.scroller.contentSize = s;
  
  int count = 0;
  for ( NSDictionary *edition in self.editions ) {
    
    SCPREditionAtomViewController *atom = nil;
    atom = [[SCPREditionAtomViewController alloc]
                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPREditionAtomViewController"]
                                           bundle:nil];
    
    atom.parentMolecule = self;
    atom.relatedArticle = edition;
    atom.view.frame = atom.view.frame;
    
    CGFloat adjuster = [Utilities isIOS7] ? 0.0 : -20.0;
    if ( !self.fromNewsPage ) {
      adjuster = 0.0;
    }

    
    [self.displayVector addObject:atom];
    atom.view.frame = CGRectMake(count*widthToUse,
                                 adjuster,
                                 widthToUse,
                                 heightToUse-adjuster);
    atom.index = count;
    [atom mergeWithArticle];
    
    [self.scroller addSubview:atom.view];
    count++;
    
  }
  
  [self.scroller setContentOffset:CGPointMake(index*self.scroller.frame.size.width,
                                              0.0)];
  
  self.currentAtom = [self.displayVector objectAtIndex:index];

  [self sendAnalysis];

  [[ContentManager shared] setFocusedContentObject:self.currentAtom.relatedArticle];
  
  SCPRTitlebarViewController *titleBar = [[Utilities del] globalTitleBar];
  
  if ( ![[ContentManager shared] userIsViewingExpandedDetails] ) {
    if ( [Utilities isIpad] ) {
      [titleBar applyPagerWithCount:[self.editions count]
                      currentPage:index];
    } else {
      self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(10.0, 0.0, 280.0, 20.0)];
      self.pageControl.userInteractionEnabled = NO;
      self.pageControl.numberOfPages = [self.editions count];
      [self.infoSeatView addSubview:self.pageControl];
      [[DesignManager shared] avoidNeighbor:self.editionInfoLabel
                                   withView:self.pageControl
                                  direction:NeighborDirectionAbove
                                    padding:3.0];
      [[DesignManager shared] alignHorizontalCenterOf:self.pageControl
                                             withView:self.editionInfoLabel];
      
    }
  }
  
  if ( [Utilities isIpad] ) {
    [self.view bringSubviewToFront:self.editionInfoLabel];
  } else {
    [self.view bringSubviewToFront:self.infoSeatView];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"editions_finished_building"
                                                      object:nil];
  
}

- (void)pushToCurrentAtomDetails {
  [self pushToAtomDetails:self.currentIndex];
}

- (void)pushToAtomDetails:(NSInteger)index {
  
  [self.scroller setContentOffset:CGPointMake(index*self.scroller.frame.size.width,
                                              0.0)];
  self.currentAtom = [self.displayVector objectAtIndex:index];
  [self.currentAtom buttonTapped:self.currentAtom.expandButton];
  
}

- (void)sendAnalysis {
  
  NSMutableDictionary *params = [[[AnalyticsManager shared] paramsForArticle:self.currentAtom.relatedArticle] mutableCopy];
  [params setObject:[NSDate stringFromDate:[NSDate date]
                                withFormat:@"MMM dd, YYYY HH:mm"]
             forKey:@"date"];

  [params setObject:@"Editions"
             forKey:@"accessed_from"];
  
  NSString *currIndexStr = [NSString stringWithFormat:@"%d",(int) self.currentAtom.index];
  [params setObject:currIndexStr
             forKey:@"stack_depth"];
  
  
  [params setObject: ([[AudioManager shared] isPlayingAnyAudio]) ? @"YES" : @"NO" forKey:@"audio_on"];

  /*NSString *eid = [NSString stringWithFormat:@"%@",[edition objectForKey:@"id"]];
  [params setObject:eid forKey:@"edition_id"];*/
  
  [[AnalyticsManager shared] logEvent:@"abstract_read"
                       withParameters:params];
  
  if (self.currentAtom.index == ([self.editions count] - 1)) {
    NSString *abstractCount = [NSString stringWithFormat:@"%d",(int)[self.editions count]];
    [[AnalyticsManager shared] logEvent:@"edition_completed"
                         withParameters:@{ @"edition_id" : [self.editionShell objectForKey:@"id"],
                                           @"edition_published_date" : [self.editionShell objectForKey:@"published_at"],
                                           @"title" : [self.editionShell objectForKey:@"title"],
                                           @"abstract_count" : abstractCount}];
  }
  
}

#pragma mark - Backable
- (void)backTapped {
  
  [[ContentManager shared] popFromResizeVector];
  
  if ( self.parentEditionContentViewController ) {
    
    if ( [self.parentEditionContentViewController isKindOfClass:[SCPREditionCrystalViewController class]] ) {
      
      SCPREditionCrystalViewController *svc = (SCPREditionCrystalViewController*)self.parentEditionContentViewController;
      [(SCPREditionMineralViewController*)svc.parentMineral setMoleculePushed:NO];
      svc.pushedContent = nil;

    }
    
  } else {
    
    SCPRViewController *vc = [[Utilities del] viewController];
    vc.globalGradient.alpha = 0.0;
  }

#ifdef AGGRESSIVE_DEALLOCATION
  for ( SCPREditionAtomViewController *atom in self.displayVector ) {
    [atom.splashImageView setImage:nil];
    [atom.splashImageView removeFromSuperview];
  }
#endif
  
  [[[Utilities del] globalTitleBar] pop];
  

  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    [[[Utilities del] masterRootController] killAdOffscreen:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }
  
}

#pragma mark - Delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  NSInteger index = floorf(self.scroller.contentOffset.x/self.scroller.frame.size.width);
  if ( index >= [self.displayVector count] ) {
    index = [self.displayVector count]-1;
  }
  if ( index < 0 ) {
    index = 0;
  }
  
  self.currentAtom = [self.displayVector objectAtIndex:index];
  [[ContentManager shared] setFocusedContentObject:self.currentAtom.relatedArticle];
  
  if ( [Utilities isIpad] ) {
    SCPRTitlebarViewController *titleBar = [[Utilities del] globalTitleBar];
    titleBar.pager.currentPage = index;
  } else {
    self.pageControl.currentPage = index;
  }
  
  BOOL noMovement = self.currentIndex == index;
  if ( !noMovement ) {
    UISwipeGestureRecognizerDirection dir = self.currentIndex > index ? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionLeft;
    BOOL penultimate = NO;
    if ( dir == UISwipeGestureRecognizerDirectionLeft ) {
      penultimate = index == [self.editions count]-1;
    } else {
      penultimate = index == 0;
    }
    
    UIView *playerBar = [[[Utilities del] globalPlayer] view];
    
    [[ContentManager shared] tickSwipe:dir
                                inView:scrollView
                                penultimate:penultimate
                         silenceVector:[@[ self.editionInfoLabel ] mutableCopy]];
  }
  
  self.currentIndex = index;
  [self sendAnalysis];
  
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  
  if ( [[ContentManager shared] adReadyOffscreen] ) {
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root undeliverAd];
    
    [[AnalyticsManager shared] logEvent:@"ad_was_loaded_but_avoided"
                         withParameters:@{}];
    
  }
  
  [UIView animateWithDuration:0.25 animations:^{
    self.scroller.alpha = 0.0;
  }];
}

- (void)handleRotationPost {
  [[[Utilities del] globalTitleBar] restamp];
  [self setupWithEditions:self.editions andIndex:self.currentIndex];
  [UIView animateWithDuration:0.25 animations:^{
    self.scroller.alpha = 1.0;
  }];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EDITION MOLEUCLE...");
}
#endif

@end
