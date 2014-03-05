//
//  SCPRReloadViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRReloadViewController.h"
#import "global.h"

@interface SCPRReloadViewController ()

@end

@implementation SCPRReloadViewController

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
  
  self.letterSeat.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.view.backgroundColor = [[DesignManager shared] number1pencilColor];
  self.spinner.view.alpha = 0.0;
  
  for ( unsigned i = 1; i <= 6; i++ ) {
    NSString *key = [NSString stringWithFormat:@"l%d",i];
    UILabel *label = (UILabel*)[self valueForKey:key];
    label.alpha = 0.0;
    label.textColor = [[DesignManager shared] twitterBlueColor];
    [label titleizeText:label.text bold:YES];
  }
    // Do any additional setup after loading the view from its nib.
}

- (void)setupWithScroller:(UIScrollView *)scroll delegate:(id<Reloadable>)delegate {
  self.observedScroller = scroll;
  self.delegate = delegate;
}

- (void)setObservedScroller:(UIScrollView *)observedScroller {
  
  if ( _observedScroller && !observedScroller ) {
    [_observedScroller removeObserver:self
                           forKeyPath:@"contentOffset"];
  }
  
  _observedScroller = observedScroller;
  
  if ( observedScroller ) {
    [self.view removeFromSuperview];
    self.view.frame = CGRectMake(0.0,-1.0*(self.view.frame.size.height),
                               observedScroller.frame.size.width,
                               self.view.frame.size.height);
    [self.observedScroller addSubview:self.view];
    [self.observedScroller addObserver:self
                          forKeyPath:@"contentOffset"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
  }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  CGPoint contentOffset = [[change objectForKey:@"new"] CGPointValue];
  if ( contentOffset.y >= 0.0 ) {
    return;
  }
  
  CGFloat yOffset = fabsf(contentOffset.y);
  
  CGFloat slice = self.view.frame.size.height / 6.0;
  NSInteger index = floor(yOffset / slice);
  
  for ( unsigned i = 0; i < 6; i++ ) {
    NSString *key = [NSString stringWithFormat:@"l%d",i+1];
    UILabel *label = (UILabel*)[self valueForKey:key];
    
    if ( yOffset == 0.0 ) {
      label.alpha = 0.0;
      continue;
    }
    
    if ( i < index ) {
      label.alpha = 1.0;
    } else if ( i == index ) {
      CGFloat leftOver = (CGFloat)((int)yOffset % (int)slice);
      label.alpha = leftOver / slice;
      
      if ( i == 5 && label.alpha >= 0.1 ) {
        self.hot = YES;
        self.observedScroller.delegate = self;
      } else {
        self.hot = NO;
        self.observedScroller.delegate = nil;
      }
      
    } else {
      label.alpha = 0.0;
    }
  }
  
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if ( self.hot ) {
    self.hot = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadBegan)
                                                 name:@"spinner_appeared"
                                               object:nil];
    
    [UIView animateWithDuration:0.22 animations:^{
      self.spinner.view.alpha = 1.0;
      [self.spinner spinInPlaceWithFinishedToken:[self.delegate unfreezeKey]];
      self.observedScroller.contentInset = UIEdgeInsetsMake(self.view.frame.size.height, 0.0, 0.0, 0.0);
    }];

    
  }
}

- (void)reloadBegan {
  [self handleReload];
}

- (void)handleReload {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"spinner_appeared"
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(finish)
                                               name:[self.delegate unfreezeKey]
                                             object:nil];
  [self.delegate reload];
  
}

- (void)finish {
  [UIView animateWithDuration:0.25 animations:^{
    self.observedScroller.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
  }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
