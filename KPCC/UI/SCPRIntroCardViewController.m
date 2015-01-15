//
//  SCPRIntroCardViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 11/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRIntroCardViewController.h"
#import "DesignManager.h"

@interface SCPRIntroCardViewController ()

@end

@implementation SCPRIntroCardViewController

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
  
  [self.view removeConstraints:@[ self.cornerImageLeftAnchor, self.cornerImageTopAnchor, self.cornerImageTmpSizeX, self.cornerImageTmpSizeY ]];
    // Do any additional setup after loading the view from its nib.
}

- (void)setupForCardType:(CardType)type {
  
                               
  self.cardTopAnchor.constant = [Utilities isLandscape] ? 60.0 : 135.0;
  NSArray *cards = [Utilities loadJson:@"intro_cards"];
  NSString *mainImage = [NSString stringWithFormat:@"onboarding-card-step%d",(int)type+1];
  self.cardType = type;
  NSDictionary *meta = [cards objectAtIndex:type];
  CornerPosition position = [[meta objectForKey:@"ornament"] intValue];
  if ( position != CornerPositionNone ) {
    NSString *ornamentImage = [NSString stringWithFormat:@"onboarding-magnifier-step%d",(int)type+1];
    UIImage *ornie = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:ornamentImage
                                                                                      ofType:@"png"]];
    self.ornamentImage = [[UIImageView alloc] initWithImage:ornie];
    [self.view addSubview:self.ornamentImage];
  }
  
  self.splashImage.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                             pathForResource:mainImage
                                                             ofType:@"jpg"]];
  
  [self placeOrnamentInCorner:position];
  

  
  self.pager.currentPage = type;
  
  [self.nextButton addTarget:self
                      action:@selector(buttonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  
  if ( self.cardType == CardTypeWelcome ) {
    self.buttonCenterXAnchor.constant = -416.0;
    self.buttonCenterYAnchor.constant = -168.0;
  }
}

- (void)buttonTapped:(id)sender {
  
  SCPRIntroductionViewController *ivc = (SCPRIntroductionViewController*)self.parentIntro;
  if ( self.cardType + 1 == CardTypeNone ) {
    [ivc finishTour];
  } else {
    [ivc nextCard];
  }
  
}

- (void)placeOrnamentInCorner:(CornerPosition)position {
  
  self.ornamentImage.alpha = 1.0;
  
  if ( self.cornerImageAnchors ) {
    [self.view removeConstraints:self.cornerImageAnchors];
  }
  
  /*
  switch (position) {
    case CornerPositionNorthwest:
      self.ornamentImage.frame = CGRectMake(0.0,-25.0,self.ornamentImage.frame.size.width,
                                            self.ornamentImage.frame.size.height);
      break;
    case CornerPositionNortheast:
      self.ornamentImage.frame = CGRectMake(self.view.frame.size.width-self.ornamentImage.frame.size.width,
                                            0.0, self.ornamentImage.frame.size.width,
                                            self.ornamentImage.frame.size.height);
      break;
    case CornerPositionSoutheast:
      self.ornamentImage.frame = CGRectMake(self.view.frame.size.width-self.ornamentImage.frame.size.width,
                                            self.view.frame.size.height-self.ornamentImage.frame.size.height,
                                            self.ornamentImage.frame.size.width,
                                            self.ornamentImage.frame.size.height);
      break;
    case CornerPositionSouthwest:
      self.ornamentImage.frame = CGRectMake(0.0, self.view.frame.size.height-self.ornamentImage.frame.size.height,
                                            self.ornamentImage.frame.size.width,
                                            self.ornamentImage.frame.size.height);
      break;
    case CornerPositionNone:
      self.ornamentImage.alpha = 0.0;
  }*/
  
  NSArray *hAnchors = nil;
  NSArray *vAnchors = nil;
  switch (position) {
    case CornerPositionNorthwest:
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|[img(%1.1f)]",self.ornamentImage.frame.size.width]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[img(%1.1f)]",self.ornamentImage.frame.size.height]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      break;
    case CornerPositionNortheast:
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[img(%1.1f)]|",self.ornamentImage.frame.size.width]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[img(%1.1f)]",self.ornamentImage.frame.size.height]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      break;
    case CornerPositionSoutheast:
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[img(%1.1f)]|",self.ornamentImage.frame.size.width]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[img(%1.1f)]|",self.ornamentImage.frame.size.height]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      break;
    case CornerPositionSouthwest:
      hAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|[img(%1.1f)]",self.ornamentImage.frame.size.width]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      vAnchors = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[img(%1.1f)]|",self.ornamentImage.frame.size.height]
                                                         options:0
                                                         metrics:nil
                                                           views:@{ @"img" : self.ornamentImage }];
      break;
    case CornerPositionNone:
      self.ornamentImage.alpha = 0.0;
  }
  
  [self.ornamentImage setTranslatesAutoresizingMaskIntoConstraints:NO];
  NSMutableArray *combined = [hAnchors mutableCopy];
  [combined addObjectsFromArray:vAnchors];
  self.cornerImageAnchors = [NSArray arrayWithArray:combined];
  [self.view addConstraints:self.cornerImageAnchors];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
