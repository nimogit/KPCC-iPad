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
    //[self setAutomaticallyAdjustsScrollViewInsets:NO];
  }
  
  self.scroller.pagingEnabled = YES;
  self.scroller.delegate = self;
  self.cloakView.alpha = 0.0;
  if ( ![Utilities isIOS7] ) {
    if ( self.fromNewsPage ) {
      
    }
  }
  
  [self setNeedsContentSnap:YES];
  
  SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
  root.adSilenceVector = [@[ self.editionInfoLabel ] mutableCopy];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  if ( self.needsPush ) {
    self.needsPush = NO;
  }
  
  [self.view.superview setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
  SCPRViewController *vc = [[Utilities del] viewController];
  vc.globalGradient.alpha = 1.0;
}

- (void)viewDidLayoutSubviews {
  if ( self.needsContentSnap ) {
    self.needsContentSnap = NO;
    [self snapContentSize];
  }
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

  [self.view printDimensionsWithIdentifier:@"Editions Molecule"];
  
  NSString *pa = [self.editionShell objectForKey:@"published_at"];
  NSDate *published = [Utilities dateFromRFCString:pa];
  NSString *timeString = [NSDate stringFromDate:published
                                     withFormat:@"EEEE, ha"];
  NSString *full = [NSString stringWithFormat:@"THE SHORT LIST: %@",[timeString uppercaseString]];
  [self.editionInfoLabel titleizeText:full bold:NO];
  self.editionInfoLabel.alpha = 1.0;
  
  self.editions = editions;
  self.currentIndex = index;
  self.displayVector = [NSMutableArray new];
  
  [self.scroller setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  self.metricChain = [NSMutableDictionary new];
  int count = 0;
  
  SCPREditionAtomViewController *previousAtom = nil;
  for ( NSDictionary *edition in self.editions ) {
    
    SCPREditionAtomViewController *atom = nil;
    atom = [[SCPREditionAtomViewController alloc]
                                           initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPREditionAtomViewController"]
                                           bundle:nil];
    
    atom.parentMolecule = self;
    atom.relatedArticle = edition;
    atom.view.frame = atom.view.frame;
    [self.displayVector addObject:atom];

    atom.index = count;
    [atom mergeWithArticle];
    
    [self.scroller addSubview:atom.view];
    [atom.view setTranslatesAutoresizingMaskIntoConstraints:NO];

    
    if ( previousAtom ) {
      
      NSString *HF = [NSString stringWithFormat:@"H:[prev][me]"];
      if ( count == self.editions.count-1 ) {
        HF = [NSString stringWithFormat:@"H:[prev][me]|"];
      }
      NSString *VF = [NSString stringWithFormat:@"V:|[me]"];
      
      NSArray *linkToPreviousH = [NSLayoutConstraint constraintsWithVisualFormat:HF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"prev" : previousAtom.view,
                                                                                    @"me" : atom.view }];
      NSArray *linkToPreviousV = [NSLayoutConstraint constraintsWithVisualFormat:VF
                                                                        options:0
                                                                        metrics:nil
                                                                        views:@{ @"me" : atom.view }];
      
      NSMutableArray *linkToPrevious = [linkToPreviousH mutableCopy];
      [linkToPrevious addObjectsFromArray:linkToPreviousV];
      [self.scroller addConstraints:linkToPrevious];
      

      
    } else {
      
      NSString *HF = [NSString stringWithFormat:@"H:|[me]"];
      NSString *VF = [NSString stringWithFormat:@"V:|[me]"];
      
      NSArray *linkToParentH = [NSLayoutConstraint constraintsWithVisualFormat:HF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"me" : atom.view }];
      NSArray *linkToParentV = [NSLayoutConstraint constraintsWithVisualFormat:VF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"me" : atom.view }];
      
      NSMutableArray *linkToParent = [linkToParentH mutableCopy];
      [linkToParent addObjectsFromArray:linkToParentV];
      [self.scroller addConstraints:linkToParent];
      
    }
    
    NSLayoutConstraint *wC = [NSLayoutConstraint constraintWithItem:atom.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.scroller.frame.size.width];
    
    
    NSLayoutConstraint *hC = [NSLayoutConstraint constraintWithItem:atom.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.scroller.frame.size.height];
    
    NSDictionary *metrics = @{ @"width" : wC,
                               @"height" : hC };
    [self.metricChain setObject:metrics
                         forKey:@(count)];
    
    [atom.view addConstraint:wC];
    [atom.view addConstraint:hC];
    
    previousAtom = atom;
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
  
  [self snapContentSize];
  
  if ( [Utilities isIpad] ) {
    [self.view bringSubviewToFront:self.editionInfoLabel];
  } else {
    [self.view bringSubviewToFront:self.infoSeatView];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"editions_finished_building"
                                                      object:nil];
  
}

- (void)snapContentSize {
  self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width*self.editions.count,
                                         self.scroller.frame.size.height);


  
  for ( SCPREditionAtomViewController *atom in self.displayVector ) {
    atom.bottomAnchor.constant = [Utilities isLandscape] ? 20.0 : 26.0;
    atom.cardHeightAnchor.constant = [Utilities isLandscape] ? 378.0 : 496.0;
    [atom.detailsSeatView layoutIfNeeded];
    [atom.view layoutIfNeeded];
    [atom.view updateConstraintsIfNeeded];
  }
  
  for ( NSDictionary *metrics in [self.metricChain allValues] ) {
    NSLayoutConstraint *w = metrics[@"width"];
    [w setConstant:self.scroller.frame.size.width];
    
    NSLayoutConstraint *h = metrics[@"height"];
    [h setConstant:self.scroller.frame.size.height];
  }
  

  
  [self.scroller setContentOffset:CGPointMake(self.scroller.frame.size.width*self.currentIndex,
                                              0.0)];
  [self.scroller setNeedsLayout];
  [self.scroller setNeedsUpdateConstraints];
  
  NSLog(@"Content Width : %1.1f",self.scroller.contentSize.width);
  
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
  
  [UIView animateWithDuration:0.25 animations:^{
    self.cloakView.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    [[ContentManager shared] popFromResizeVector];
    
    if ( self.parentEditionContentViewController ) {
      
      if ( [self.parentEditionContentViewController isKindOfClass:[SCPREditionCrystalViewController class]] ) {
        
        SCPREditionCrystalViewController *svc = (SCPREditionCrystalViewController*)self.parentEditionContentViewController;
        [(SCPREditionMineralViewController*)svc.parentMineral setMoleculePushed:NO];
        svc.pushedContent = nil;
        
      } else {
        SCPRViewController *vc = [[Utilities del] viewController];
        vc.globalGradient.alpha = 0.0;
      }
    }
    
#ifdef AGGRESSIVE_DEALLOCATION
    for ( SCPREditionAtomViewController *atom in self.displayVector ) {
      [atom.splashImageView setImage:nil];
      [atom.splashImageView removeFromSuperview];
    }
#endif
    
    self.scroller.alpha = 0.0;
    
    [[[Utilities del] globalTitleBar] pop];
    
    if ( [[ContentManager shared] adReadyOffscreen] ) {
      [[[Utilities del] masterRootController] killAdOffscreen:^{
        [self.navigationController popViewControllerAnimated:YES];
      }];
    } else {
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];

  
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
  [self setNeedsContentSnap:YES];
  [self.view layoutIfNeeded];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EDITION MOLEUCLE...");
}
#endif

@end
