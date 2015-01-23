//
//  SCPROnboardingFlowViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingFlowViewController.h"
#import "SCPROnboardingCardViewController.h"
#import "global.h"
#import "SCPRPlayerWidgetViewController.h"
#import "SCPRTitlebarViewController.h"
#import "SCPRViewController.h"

@interface SCPROnboardingFlowViewController ()

@end

@implementation SCPROnboardingFlowViewController

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
  
  self.versionLabel.alpha = 0.0;
#ifndef PRODUCTION
  self.versionLabel.alpha = 1.0;
  [self.versionLabel titleizeText:[NSString stringWithFormat:@"KPCC iPad %@",[Utilities prettyVersion]]
                             bold:YES];
#endif
  
  self.view.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  self.contentStack = [[NSMutableArray alloc] init];
  self.cardScroller.scrollEnabled = NO;
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.notRightNowButton.titleLabel.font.pointSize]
                                forButton:self.notRightNowButton];
  
  self.topAnchor.constant = 15.0;
  
  
  [self setup];
  [self setNeedsSnap:YES];
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews {
  if ( self.needsSnap ) {
    self.needsSnap = NO;
    
    [self.view printDimensionsWithIdentifier:@"Container view"];
    [self.cardScroller printDimensionsWithIdentifier:@"Card Scroller"];

    [self prepOrientation];
    [self.cardScroller setNeedsLayout];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [self prepOrientation];
  [self setNeedsSnap:YES];
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setup {
  
  SCPRTitlebarViewController *tvc = [[Utilities del] globalTitleBar];
  [tvc applyGrayBackground];
  [tvc applyKpccLogo];
  
  self.metricChain = [NSMutableArray new];
  
  [self pushCard:FlowStepLanding];

  
  //self.cardScroller.backgroundColor = [[DesignManager shared] prettyRandomColor];
}

- (IBAction)buttonTapped:(id)sender {
  SCPROnboardingCardViewController *topCard = [self.contentStack lastObject];
  if ( [topCard.myCardContent respondsToSelector:@selector(backTapped)] ) {
    [topCard.myCardContent backTapped];
  }
  [self finish];
}

- (void)pushCard:(NSInteger)step {
  
  SCPROnboardingCardViewController *card = [[SCPROnboardingCardViewController alloc]
                                            initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPROnboardingCardViewController"]
                                            bundle:nil];
  
  

  
  [self.contentStack addObject:card];
  
  self.cardScroller.contentSize = CGSizeMake(self.cardScroller.frame.size.width*[self.contentStack count],
                                             self.cardScroller.frame.size.height);
  
  [self.cardScroller addSubview:card.view];
  
  [card.view setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSString *hFmt = @"";
  NSArray *hConstraints = nil;
  if ( self.contentStack.count == 1 ) {
    hFmt = @"H:|[card]";
    hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hFmt
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{ @"card" : card.view }];
  } else {
    
    SCPROnboardingCardViewController *prevCard = [self.contentStack objectAtIndex:step-2];
    [prevCard.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    hFmt = @"H:[prev][card]";
    hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hFmt
                                                           options:0
                                                           metrics:nil
                                                             views:@{ @"card" : card.view,
                                                                      @"prev" : prevCard.view }];
    
  }
  
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[card]"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"card" : card.view }];
  

  
  NSLayoutConstraint *co = [NSLayoutConstraint constraintWithItem:card.view
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:self.cardScroller.frame.size.width];
  [card.view addConstraint:co];
  [self.metricChain addObject:co];
  
  /*card.view.frame = CGRectMake((step-1)*self.cardScroller.frame.size.width, 0.0, self.cardScroller.frame.size.width,
                               self.cardScroller.frame.size.height);*/
  
  if ( [self.contentStack count] > 1 ) {
    card.backButton.alpha = 1.0;
  } else {
    card.backButton.alpha = 0.0;
  }
  [card setupWithStep:step andMaster:self];

  [self.cardScroller addConstraints:hConstraints];
  [self.cardScroller addConstraints:vConstraints];
  
  self.currentStepIndex = step;
  
  [UIView animateWithDuration:0.43 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self.cardScroller setContentOffset:CGPointMake((step-1)*self.cardScroller.frame.size.width,0.0)];
    for ( unsigned i = 0; i < [self.contentStack count]; i++ ) {
      SCPROnboardingCardViewController *c = [self.contentStack objectAtIndex:i];
      if ( c.myStepIndex == self.currentStepIndex ) {
        c.view.alpha = 1.0;
      } else {
        c.view.alpha = 0.0;
      }
    }
  } completion:^(BOOL finished) {
    
    /*for ( SCPROnboardingCardViewController *card in self.contentStack ) {
      card.view.backgroundColor = [[DesignManager shared] prettyRandomColor];
    }*/
    
  }];
  
  [self.cardScroller setNeedsLayout];
  
}

- (void)popCard {

  SCPROnboardingCardViewController *c = [self.contentStack lastObject];
  [self.metricChain removeLastObject];
  
  self.currentStepIndex = c.myStepIndex;
  [UIView animateWithDuration:0.43 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    [self.cardScroller setContentOffset:CGPointMake(c.view.frame.origin.x-c.view.frame.size.width,0.0)];
    for ( unsigned i = 0; i < [self.contentStack count]; i++ ) {
      SCPROnboardingCardViewController *c2 = [self.contentStack objectAtIndex:i];
      if ( c2.myStepIndex == self.currentStepIndex ) {
        c2.view.alpha = 0.0;
      } else {
        c2.view.alpha = 1.0;
      }
    }
  } completion:^(BOOL finished) {
    
    [c.view removeFromSuperview];
    [self.contentStack removeLastObject];
    
    SCPROnboardingCardViewController *newCurrent = [self.contentStack lastObject];
    self.currentStepIndex = newCurrent.myStepIndex;
    self.cardScroller.contentSize = CGSizeMake(self.cardScroller.frame.size.width*[self.contentStack count],
                                               self.cardScroller.frame.size.height);
    
    for ( unsigned i = 0; i < [self.contentStack count]; i++ ) {
      SCPROnboardingCardViewController *c1 = [self.contentStack objectAtIndex:i];
      if ( c1.myStepIndex == self.currentStepIndex ) {
        c1.view.alpha = 1.0;
      } else {
        c1.view.alpha = 0.0;
      }
    }
    
  }];
  
}

- (void)rubberBandCard:(CGFloat)distance responder:(UIResponder *)pusher {
  if ( self.rubberbandingDistance != 0.0 ) {
    return;
  }
  
  [UIView animateWithDuration:0.33 animations:^{
    self.cardScroller.center = CGPointMake(self.cardScroller.center.x,
                                           self.cardScroller.center.y-distance);
  } completion:^(BOOL finished) {
    self.rubberbandingDistance = distance;
    self.pusher = pusher;
    self.tapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector(snapRubberBand)];
    self.tapper.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.tapper];
  }];
}

- (void)snapRubberBand {
  if ( self.rubberbandingDistance == 0.0 ) {
    return;
  }
  
  [UIView animateWithDuration:0.33 animations:^{
    self.cardScroller.center = CGPointMake(self.cardScroller.center.x,
                                           self.cardScroller.center.y+self.rubberbandingDistance);
  } completion:^(BOOL finished) {
    self.rubberbandingDistance = 0.0;
    [self.pusher resignFirstResponder];
    
    [self.view removeGestureRecognizer:self.tapper];
    self.tapper = nil;
    self.pusher = nil;
    
  }];
}

- (void)handleRotationPre {
  [self snapRubberBand];
}

- (void)handleRotationPost {
  [self setNeedsSnap:YES];
}

- (void)prepOrientation {
  if ( ![Utilities isLandscape] ) {
    
    self.topAnchor.constant = 200.0;

  } else {
    
    self.topAnchor.constant = 50.0;
    
  }
  
  for ( NSLayoutConstraint *width in self.metricChain ) {
    width.constant = self.cardScroller.frame.size.width;
  }
  
  [self.cardScroller setContentOffset:CGPointMake((self.currentStepIndex-1)*self.cardScroller.frame.size.width,0.0)];
  [self.cardScroller layoutIfNeeded];

}

- (void)unplug {
  [[[Utilities del] globalPlayer].view setHidden:NO];
}

- (void)finish {

    
  SCPRViewController *vc = [[Utilities del] viewController];
  
  if ( [[SocialManager shared] isConnected] ) {
    [vc primeUI:ScreenContentTypeProfilePage newsPath:@""];
  } else {
    [vc primeUI:ScreenContentTypeCompositePage newsPath:@""];
  }
    
  
  [[[Utilities del] globalPlayer].view setHidden:NO];
  [[[Utilities del] globalTitleBar] morph:BarTypeDrawer
                                container:nil];
  

}



@end
