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
#import "SCPRDFPViewController.h"

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
    self.intermediaryAppearance = YES;
    [self pushToCurrentAtomDetails];
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
  self.displayChain = [NSMutableArray new];
  
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
      
      BOOL saveTrailing = NO;
      
      NSString *HF = [NSString stringWithFormat:@"H:[prev][me]"];
      if ( count == self.editions.count-1 ) {
        HF = [NSString stringWithFormat:@"H:[prev][me]|"];
        saveTrailing = YES;
      }
      NSString *VF = [NSString stringWithFormat:@"V:|[me]"];
      
      NSArray *linkToPreviousH = [NSLayoutConstraint constraintsWithVisualFormat:HF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"prev" : previousAtom.view,
                                                                                    @"me" : atom.view }];
      
      if ( saveTrailing ) {
        for ( NSLayoutConstraint *c in linkToPreviousH ) {
          if ( c.firstAttribute == NSLayoutAttributeTrailing || c.firstAttribute == NSLayoutAttributeRight ) {
            if ( c.firstItem == self.scroller || c.secondItem == self.scroller ) {
              self.trailingConstraint = c;
              break;
            }
          }
        }
      }
      
      NSArray *linkToPreviousV = [NSLayoutConstraint constraintsWithVisualFormat:VF
                                                                        options:0
                                                                        metrics:nil
                                                                        views:@{ @"me" : atom.view }];
      
      NSMutableArray *linkToPrevious = [linkToPreviousH mutableCopy];
      [linkToPrevious addObjectsFromArray:linkToPreviousV];
      [self.scroller addConstraints:linkToPrevious];
      [self.displayChain addObject:linkToPrevious];

      
    } else {
      
      NSString *HF = [NSString stringWithFormat:@"H:|[me]"];
      NSString *VF = [NSString stringWithFormat:@"V:|[me]"];
      
      NSArray *linkToParentH = [NSLayoutConstraint constraintsWithVisualFormat:HF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"me" : atom.view }];
      
      for ( NSLayoutConstraint *c in linkToParentH ) {
        if ( c.firstAttribute == NSLayoutAttributeLeft || c.firstAttribute == NSLayoutAttributeLeading ) {
          if ( c.firstItem == self.scroller || c.secondItem == self.scroller ) {
            self.leadingConstraint = c;
            break;
          }
        }
      }
      
      NSArray *linkToParentV = [NSLayoutConstraint constraintsWithVisualFormat:VF
                                                                         options:0
                                                                         metrics:nil
                                                                           views:@{ @"me" : atom.view }];
      
      NSMutableArray *linkToParent = [linkToParentH mutableCopy];
      [linkToParent addObjectsFromArray:linkToParentV];
      [self.scroller addConstraints:linkToParent];
      [self.displayChain addObject:linkToParent];
      
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
  [self snapContentSize:NO];
}

- (void)snapContentSize:(BOOL)animated {

  [self.scroller layoutSubviews];
  
  CGFloat addition = self.currentAdController ? self.scroller.frame.size.width : 0.0f;
  self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width*self.editions.count+addition,
                                         self.scroller.frame.size.height);


  
  for ( SCPREditionAtomViewController *atom in self.displayVector ) {
    atom.bottomAnchor.constant = [Utilities isLandscape] ? 20.0 : 26.0;
    atom.cardHeightAnchor.constant = [Utilities isLandscape] ? 378.0 : 496.0;
    [atom.view layoutSubviews];
    [atom.view updateConstraints];
  }
  
  for ( NSDictionary *metrics in [self.metricChain allValues] ) {
    NSLayoutConstraint *w = metrics[@"width"];
    [w setConstant:self.scroller.frame.size.width];
    
    NSLayoutConstraint *h = metrics[@"height"];
    [h setConstant:self.scroller.frame.size.height];
  }
  
  if ( self.adConstraints ) {
    NSLayoutConstraint *w = self.adConstraints[@"width"];
    [w setConstant:self.scroller.frame.size.width];
    
    NSLayoutConstraint *h = self.adConstraints[@"height"];
    [h setConstant:self.scroller.frame.size.height];
  }
  

  [self.scroller setContentOffset:CGPointMake(self.scroller.frame.size.width*self.currentIndex,
                                              0.0) animated:animated];
  
  
  NSLog(@"Content Width : %1.1f",self.scroller.contentSize.width);
  
}

- (void)insertAdAtIndex:(NSInteger)index {
  self.adIndex = index;
  self.pushedConstraints = [NSMutableDictionary new];
  
  if ( index + 1 <= [self.displayVector count]-1 ) {
    NSArray *nextConstraints = self.displayChain[index+1];
    if ( index == 0 ) {
      nextConstraints = self.displayChain[0];
    }
    NSLayoutConstraint *leftSide = nil;
    for ( NSLayoutConstraint *constraint in nextConstraints ) {
      if ( constraint.firstAttribute == NSLayoutAttributeLeading || constraint.firstAttribute == NSLayoutAttributeLeft ) {
        leftSide = constraint;
      }
    }
    
    if ( leftSide ) {
      [self.scroller removeConstraint:leftSide];
      [self.pushedConstraints setObject:leftSide
                                 forKey:@"next"];
    }
    
  } else {

    NSArray *currentConstraints = self.displayChain[index-1];
    NSLayoutConstraint *rightSide = nil;
    for ( NSLayoutConstraint *constraint in currentConstraints ) {
      if ( constraint.firstAttribute == NSLayoutAttributeRight || constraint.firstAttribute == NSLayoutAttributeTrailing ) {
        rightSide = constraint;
      }
    }
    
    if ( rightSide ) {
      [self.scroller removeConstraint:rightSide];
      [self.pushedConstraints setObject:rightSide
                                 forKey:@"rightAnchor"];
    }
    
  }
  
  SCPRDFPViewController *dfp = [[SCPRDFPViewController alloc]
                                initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRDFPViewController"]
                                bundle:nil];
  dfp.view.frame = dfp.view.frame;
  [self.scroller addSubview:dfp.view];
  [dfp armSwipers];
  
  SCPREditionAtomViewController *prevAtom = nil;
  SCPREditionAtomViewController *nextAtom = nil;
  if ( index != 0 ) {
    prevAtom = self.displayVector[index-1];
  } else {
    
  }
  if ( self.pushedConstraints[@"next"] ) {
    if ( index != 0 ) {
      nextAtom = self.displayVector[index+1];
    } else {
      nextAtom = self.displayVector[1];
    }
  }
  
  NSString *fmt = @"H:";
  NSMutableDictionary *views = [@{ @"me" : dfp.view } mutableCopy];
  
  if ( prevAtom ) {
    fmt = [fmt stringByAppendingString:@"[prev][me]"];
    views[@"prev"] = prevAtom.view;
  } else {
    fmt = [fmt stringByAppendingString:@"|"];
  }
  if ( nextAtom ) {
    if ( index == 0 ) {
      fmt = [fmt stringByAppendingString:@"[me][next]"];
    } else {
      fmt = [fmt stringByAppendingString:@"[next]"];
    }
    views[@"next"] = nextAtom.view;
    if ( index + 1 == self.displayVector.count-1 ) {
      fmt = [fmt stringByAppendingString:@"|"];
    }
  } else {
    fmt = [fmt stringByAppendingString:@"|"];
  }
  
  UIView *adView = dfp.view;
  [dfp.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:fmt
                                                                  options:0
                                                                  metrics:nil
                                                                    views:views];
  
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : adView }];
  
  NSLayoutConstraint *wC = [NSLayoutConstraint constraintWithItem:dfp.view
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:self.scroller.frame.size.width];
  
  
  NSLayoutConstraint *hC = [NSLayoutConstraint constraintWithItem:dfp.view
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:self.scroller.frame.size.height];
  
  NSDictionary *metrics = @{ @"width" : wC,
                             @"height" : hC,
                             @"layoutH" : hConstraints,
                             @"layoutV" : vConstraints };
  
  self.adConstraints = [metrics mutableCopy];
  
  [dfp.view addConstraint:wC];
  [dfp.view addConstraint:hC];
  [self.metricChain setObject:self.adConstraints
                       forKey:@"ad"];
  
  dfp.delegate = self;
  [dfp loadDFPAd];
  [self.scroller addConstraints:hConstraints];
  [self.scroller addConstraints:vConstraints];
  self.currentAdController = dfp;
  
  [self snapContentSize];

  
  self.adIsHot = YES;
  
}

- (void)removeAdFromIndex:(NSInteger)index {
  [UIView animateWithDuration:0.33 animations:^{
    [self.currentAdController.view setAlpha:0.0];
  } completion:^(BOOL finished) {
    [self.currentAdController.view removeFromSuperview];
    self.currentAdController = nil;
    for ( NSLayoutConstraint *c in [self.pushedConstraints allValues] ) {
      [self.scroller addConstraint:c];
    }
    [self.metricChain removeObjectForKey:@"ad"];
    
    [UIView animateWithDuration:0.33 animations:^{
      [self snapContentSize];
      self.adConstraints = nil;
      self.pushedConstraints = nil;
      self.adIsHot = NO;
      self.adIndex = -1;
      SCPRTitlebarViewController *titleBar = [[Utilities del] globalTitleBar];
      titleBar.pager.currentPage = index;
      
    }];

    
  }];
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

#pragma mark - DFP delegate
- (void)adDidFinishLoading {
  
}

- (void)adDidFail {
  
}

- (void)adWillDismiss:(DismissDirection)direction {
  
  self.dismissDirection = direction;
  [self removeAdFromIndex:self.adIndex];
  [UIView animateWithDuration:0.25 animations:^{
    self.editionInfoLabel.alpha = 1.0;
  }];
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
  

  BOOL skipDot = NO;
  BOOL noMovement = self.currentIndex == index;
  if ( !noMovement ) {

    [[ContentManager shared] tickSwipe:UISwipeGestureRecognizerDirectionLeft
                                inView:scrollView
                           penultimate:NO
                         silenceVector:[@[ self.editionInfoLabel ] mutableCopy]];
    
    if ( [[ContentManager shared] adReadyOffscreen] ) {
      if ( self.adIsHot && index == self.adIndex ) {
        [UIView animateWithDuration:0.25 animations:^{
          self.editionInfoLabel.alpha = 0.0;
        }];
        [[ContentManager shared] adDeliveredSuccessfully];
        self.adIsHot = NO;
        skipDot = YES;
      } else {
        
        if ( !self.adIsHot ) {
          NSInteger nextIndex = index > self.currentIndex ? index + 1 : index - 1;
          nextIndex = nextIndex < 0 ? 1 : nextIndex;
          
          self.currentIndex = index;
          [self insertAdAtIndex:nextIndex];
        }
        
      }
    } else {
      [UIView animateWithDuration:0.25 animations:^{
        self.editionInfoLabel.alpha = 1.0;
      }];
    }
    
  }
 
  if ( !skipDot ) {
    if ( [Utilities isIpad] ) {
      SCPRTitlebarViewController *titleBar = [[Utilities del] globalTitleBar];
      titleBar.pager.currentPage = index;
    } else {
      self.pageControl.currentPage = index;
    }
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
  [self.view layoutSubviews];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING EDITION MOLEUCLE...");
}
#endif

@end
