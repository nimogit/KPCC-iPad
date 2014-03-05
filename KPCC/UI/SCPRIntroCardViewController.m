//
//  SCPRIntroCardViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 11/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRIntroCardViewController.h"

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
    // Do any additional setup after loading the view from its nib.
}

- (void)setupForCardType:(CardType)type {
  
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
 
#ifdef FAKE_TOUR
  //self.nextButton.backgroundColor = [UIColor redColor];
#endif
  
  if ( [Utilities isLandscape] ) {
    self.splashImage.center = CGPointMake(self.splashImage.center.x,
                                          self.splashImage.center.y-80.0);
    self.pager.frame = CGRectMake(self.splashImage.frame.origin.x+20.0,
                                  self.splashImage.frame.origin.y+self.splashImage.frame.size.height-60.0,
                                  self.pager.frame.size.width,
                                  self.pager.frame.size.height);
    

    
    
    self.nextButton.frame = CGRectMake(self.splashImage.frame.origin.x+self.splashImage.frame.size.width-self.nextButton.frame.size.width-20.0,
                                  self.splashImage.frame.origin.y+self.splashImage.frame.size.height-60.0,
                                  self.nextButton.frame.size.width,
                                  self.nextButton.frame.size.height);
    
  }
  
  self.pager.currentPage = type;
  
  [self.nextButton addTarget:self
                      action:@selector(buttonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  
  if ( self.cardType == CardTypeWelcome ) {
    if ( ![Utilities isLandscape] ) {
      self.nextButton.center = CGPointMake(self.view.frame.size.width/2.0,
                                         self.view.frame.size.height/2.0+140.0);
    } else {
      self.nextButton.center = self.splashImage.center;
      self.nextButton.center = CGPointMake(self.nextButton.center.x,
                                           self.nextButton.center.y+190.0);
    }
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
  }
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
