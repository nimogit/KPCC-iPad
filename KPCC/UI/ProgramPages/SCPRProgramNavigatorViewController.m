//
//  SCPRProgramNavigatorViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/26/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProgramNavigatorViewController.h"
#import "SCPRProgramPageViewController.h"
#import "global.h"
#import "SCPRViewController.h"

@interface SCPRProgramNavigatorViewController ()

@end

@implementation SCPRProgramNavigatorViewController

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
  
  [self stretch];
  self.programScroller.delegate = self;
  self.view.backgroundColor = [[DesignManager shared] charcoalColor];
  self.cloakView.alpha = 0.0;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews {
  if ( self.needsSnap ) {
    self.needsSnap = NO;
    [self snap];
  }
}

- (void)viewDidAppear:(BOOL)animated {

}

- (void)setupWithPrograms:(NSArray *)programs {
  
  self.programDataVector = [programs mutableCopy];
  
  for ( UIView *v in [self.programScroller subviews] ) {
    [v removeFromSuperview];
  }
  
  self.view.frame = CGRectMake(0.0,0.0,self.view.frame.size.width,
                                            self.view.frame.size.height);
  self.programVector = [[NSMutableArray alloc] init];
  CGSize s = CGSizeMake([programs count]*self.programScroller.frame.size.width,
                        self.programScroller.frame.size.height);
  self.programScroller.contentSize = s;
  self.metricChain = [NSMutableDictionary new];
  [self.programScroller setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  SCPRProgramPageViewController *previousPage = nil;
  for ( unsigned i = 0; i < [programs count]; i++ ) {
    NSDictionary *program = [programs objectAtIndex:i];
    SCPRProgramPageViewController *ppvc = [[SCPRProgramPageViewController alloc]
                                           initWithNibName:[[DesignManager shared]
                                                            xibForPlatformWithName:@"SCPRProgramPageViewController"]
                                           bundle:nil];
    ppvc.view.frame = CGRectMake(i*ppvc.view.frame.size.width,0.0,
                                 ppvc.view.frame.size.width,
                                 ppvc.view.frame.size.height);
    
    [ppvc.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.programScroller addSubview:ppvc.view];
    ppvc.programObject = [[ContentManager shared] maximizedProgramForMinimized:program];
    [self.programVector addObject:ppvc];
    
    if ( previousPage ) {
      NSString *hFormat = [NSString stringWithFormat:@"H:[prev][me]"];
      if ( i == [programs count]-1 ) {
        hFormat = [NSString stringWithFormat:@"H:[prev][me]|"];
      }
      
      NSArray *hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:hFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"prev" : previousPage.view,
                                                                             @"me" : ppvc.view }];
      NSArray *vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : ppvc.view }];
      [self.programScroller addConstraints:hAnchors];
      [self.programScroller addConstraints:vAnchors];
      
    } else {
      
      NSString *hFormat = [NSString stringWithFormat:@"H:|[me]"];
      NSArray *hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:hFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{
                                                                             @"me" : ppvc.view }];
      
      NSArray *vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[me]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"me" : ppvc.view }];
      [self.programScroller addConstraints:hAnchors];
      [self.programScroller addConstraints:vAnchors];
      
    }
    
    NSLayoutConstraint *wC = [NSLayoutConstraint constraintWithItem:ppvc.view
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.programScroller.frame.size.width];
    
    
    NSLayoutConstraint *hC = [NSLayoutConstraint constraintWithItem:ppvc.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0
                                                           constant:self.programScroller.frame.size.height];
    
    NSDictionary *metrics = @{ @"width" : wC,
                               @"height" : hC };
    [self.metricChain setObject:metrics
                         forKey:@(i)];
    
    [ppvc.view addConstraints:@[wC,hC]];
    previousPage = ppvc;
    
  }
  
  self.programScroller.contentSize = CGSizeMake([self.programVector count]*self.programScroller.frame.size.width,
                                                self.programScroller.frame.size.height);
  [self setNeedsSnap:YES];
  [self.view layoutIfNeeded];
  
}

- (void)snap {
  for ( NSDictionary *metrics in [self.metricChain allValues] ) {
    NSLayoutConstraint *width = metrics[@"width"];
    NSLayoutConstraint *height = metrics[@"height"];
    [self.programScroller printDimensionsWithIdentifier:@"Scroller at Layout Time"];
    
    width.constant = self.programScroller.frame.size.width;
    height.constant = self.programScroller.frame.size.height;
  }
  [self focusShowWithIndex:self.currentIndex];
}

#pragma mark - UIScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSInteger index = floorf(self.programScroller.contentOffset.x / self.programScroller.frame.size.width);
  if ( index != self.currentIndex ) {
    [self focusShowWithIndex:index];
  }
}


- (void)focusShowWithIndex:(NSInteger)index {
  self.programScroller.userInteractionEnabled = NO;
  self.currentIndex = index;
  SCPRProgramPageViewController * ppvc = [self.programVector objectAtIndex:index];
  ppvc.mainScroller = self.programScroller;
  if ( !ppvc.programObject ) {
    NSArray *programs = [[ContentManager shared] favoritedProgramsList];
    NSDictionary *basic = [programs objectAtIndex:index];
    NSDictionary *advanced = [[ContentManager shared] maximizedProgramForMinimized:basic];
    ppvc.programObject = advanced;
  }
  [self.programScroller setContentOffset:CGPointMake(index*self.programScroller.frame.size.width,0.0)];
  [ppvc mergeWithShow];
  [ppvc fetchShowInformation];
  
  for ( unsigned i = 0; i < [self.programVector count]; i++ ) {
    if ( index == i ) {
      continue;
    }
    SCPRProgramPageViewController * ppvcd = [self.programVector objectAtIndex:i];
    [[NSNotificationCenter defaultCenter]
     removeObserver:ppvcd
     name:@"notify_listeners_of_queue_change"
     object:nil];
  }
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  [[ContentManager shared] printCacheUsage];
  NSLog(@"DEALLOCATING PROGRAM MOLECULE CONTROLLER...");
  
}
#endif

- (void)unplug {
  for ( UIView *v in [self.programScroller subviews] ) {
    [v removeFromSuperview];
  }
  
  [[ContentManager shared] popFromResizeVector];
  
  self.programVector = nil;
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  [UIView animateWithDuration:0.28 animations:^{
    self.cloakView.alpha = 1.0;
  }];
}

- (void)handleRotationPost {

  [self setupWithPrograms:self.programDataVector];
  [self focusShowWithIndex:self.currentIndex];
  [self setNeedsSnap:YES];
  
  [self.view layoutIfNeeded];
  
  self.cloakView.alpha = 0.0;
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
