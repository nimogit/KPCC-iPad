//
//  SCPRIntroductionViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 11/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRIntroductionViewController.h"
#import "SCPRIntroCardViewController.h"
#import "SCPRMasterRootViewController.h"

@interface SCPRIntroductionViewController ()

@end

@implementation SCPRIntroductionViewController

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
  
  
  self.view.backgroundColor = [[UIColor virtualBlackColor] translucify:0.75];
  self.cardScroller.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews {
  if ( self.needsSnap ) {
    self.needsSnap = NO;
    [self buildIntro];
  }
}

- (void)deactivate {
  
}

- (void)buildIntro {
  
  
  NSArray *introCards = [Utilities loadJson:@"intro_cards"];
  CGFloat width = self.cardScroller.bounds.size.width;
  
  for ( SCPRIntroCardViewController *card in self.cardVector ) {
    [card.view removeFromSuperview];
  }
  
  self.cardVector = [[NSMutableArray alloc] init];
  self.cardScroller.contentSize = CGSizeMake(width*[introCards count],
                                             self.cardScroller.bounds.size.height);
  self.cardScroller.pagingEnabled = YES;
  
  SCPRIntroCardViewController *prevCard = nil;
  for ( unsigned i = 0; i < [introCards count]; i++ ) {
    
    SCPRIntroCardViewController *card = [[SCPRIntroCardViewController alloc]
                                         initWithNibName:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRIntroCardViewController"]
                                         bundle:nil];
    card.view.frame = CGRectMake(i*width,0.0,self.cardScroller.frame.size.width,
                                 self.cardScroller.frame.size.height);
    card.parentIntro = self;
    [card setupForCardType:(int)i];
    [self.cardVector addObject:card];
    [self.cardScroller addSubview:card.view];
    [card.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSArray *hAnchors = nil;
    NSArray *vAnchors = nil;
    if ( prevCard ) {
      
      NSString *hFmt = [NSString stringWithFormat:@"H:[prev][me(%1.1f)]",self.cardScroller.frame.size.width];
      if ( i == [introCards count]-1 ) {
        hFmt = [NSString stringWithFormat:@"H:[prev][me(%1.1f)]|",self.cardScroller.frame.size.width];
      }
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:hFmt
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{ @"prev" : prevCard.view,
                                                                             @"me" : card.view }];
      
    } else {
      
      NSString *hFmt = [NSString stringWithFormat:@"H:|[me(%1.1f)]",self.cardScroller.frame.size.width];
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:hFmt
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"me" : card.view }];
      
    }
    
    vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[me(%1.1f)]",self.cardScroller.frame.size.height]
                                                       options:0
                                                       metrics:nil
                                                         views:@{ @"me" : card.view }];
    
    [self.cardScroller addConstraints:hAnchors];
    [self.cardScroller addConstraints:vAnchors];
    prevCard = card;
    
  }
  
  [UIView animateWithDuration:0.15 animations:^{
    self.cardScroller.contentOffset = CGPointMake(self.currentCard*width,
                                                  0.0);
  } completion:^(BOOL finished) {
    [UIView animateWithDuration:0.25 animations:^{
      self.cardScroller.alpha = 1.0;
    }];
  }];

}

- (void)nextCard {
  if ( self.currentCard + 1 == CardTypeNone ) {
    return;
  }
  
  self.currentCard++;
  [self.cardScroller setContentOffset:CGPointMake(self.cardScroller.contentOffset.x+self.cardScroller.frame.size.width,
                                                  self.cardScroller.contentOffset.y)
                             animated:YES];
  
}

- (void)finishTour {
  [[ContentManager shared].settings setOnboardingShown:YES];
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  [[[Utilities del] masterRootController] hideIntro];
}

#pragma mark - UIScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  int index = (int)floorf(self.cardScroller.contentOffset.x/self.cardScroller.frame.size.width);
  self.currentCard = (CardType)index;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotatable
- (void)handleRotationPre {
  [UIView animateWithDuration:0.25 animations:^{
    self.cardScroller.alpha = 0.0;
  }];
}

- (void)handleRotationPost {
  [self setNeedsSnap:YES];
  [UIView animateWithDuration:0.25 animations:^{
    self.cardScroller.alpha = 0.0;
  } completion:^(BOOL finished) {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
  }];
}

@end
