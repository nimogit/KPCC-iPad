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

- (void)viewDidAppear:(BOOL)animated {
  self.programScroller.contentSize = CGSizeMake([self.programVector count]*self.programScroller.frame.size.width,
                                                self.programScroller.frame.size.height);
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
  SCPRProgramPageViewController *program = [self.programVector objectAtIndex:self.currentIndex];
  [[[Utilities del] viewController] buildProgramPages:YES];
  [[[Utilities del] viewController] primeUI:ScreenContentTypeProgramPage newsPath:[program.programObject objectForKey:@"title"]];
  self.cloakView.alpha = 0.0;
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
