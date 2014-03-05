//
//  SCPRArmoireViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRArmoireViewController.h"
#import "SCPRSingleArticleViewController.h"

#define kTravelMarker 380.0

@interface SCPRArmoireViewController ()

@end

@implementation SCPRArmoireViewController

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
  
  self.swipeToDeploy = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(deploy)];
  self.swipeToDeploy.direction = UISwipeGestureRecognizerDirectionDown;
  
  self.tapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(decide)];
  
  [self.gripperView addGestureRecognizer:self.tapper];

  
  self.gripperView.layer.cornerRadius = 4.0;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)setContentView:(UIView *)contentView {
  _contentView = contentView;
  
  self.contentView.frame = CGRectMake(0.0,0.0,self.contentSeatView.frame.size.width,
                                      self.contentSeatView.frame.size.height);
  
  [self.contentSeatView addSubview:self.contentView];
  

  
  self.contentView.alpha = 0.0;
  
}

- (void)setTintColor:(UIColor *)tintColor {
  _tintColor = tintColor;
  
  self.contentSeatView.backgroundColor = tintColor;
  self.gripperView.backgroundColor = tintColor;
}

- (void)decide {
  if ( !self.deployed ) {
    [self deploy];
  } else {
    [self retract];
  }
}

- (void)deploy {
  
  if ( YES ) {
    SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.parent;
    SCPRAppDelegate *del = [Utilities del];
    [del cloakUIWithSlideshowFromArticle:svc.relatedArticle];
    return;
  }
  
  if ( self.deployed ) {
    return;
  }
  
  self.deployed = YES;
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.23];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(drawn)];
  self.view.center = CGPointMake(self.view.center.x,
                                 self.view.center.y+(self.view.frame.size.height-40.0));
  [UIView commitAnimations];
}

- (void)drawn {
  
  self.scrollerToDisable.scrollEnabled = NO;
  
  if ( !self.swipeToRetract ) {
    self.swipeToRetract = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(retract)];
    self.swipeToRetract.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:self.swipeToRetract];
  }
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.24];
  SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.parent;
  [svc partialWash];
  self.contentView.alpha = 1.0;
  [UIView commitAnimations];
}

- (void)retract {
  if ( !self.deployed ) {
    return;
  }
  
  self.deployed = NO;
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.24];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(faded)];
  self.contentView.alpha = 0.0;
  SCPRSingleArticleViewController *svc = (SCPRSingleArticleViewController*)self.parent;
  [svc unwash];
  [UIView commitAnimations];
}

- (void)faded {
  
  self.scrollerToDisable.scrollEnabled = YES;
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.23];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  self.view.center = CGPointMake(self.view.center.x,
                                 self.view.center.y-(self.view.frame.size.height-40.0));
  [UIView commitAnimations];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {

  NSLog(@"DEALLOCATING ARMOIRE VIEW CONTROLLER...");

}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
