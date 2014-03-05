//
//  SCPRFloatingOptionViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/27/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRFloatingOptionViewController.h"
#import "global.h"

@interface SCPRFloatingOptionViewController ()

@end

@implementation SCPRFloatingOptionViewController

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
  
  self.originalFrameHash = [[NSMutableDictionary alloc] init];
  for ( unsigned i = 0; i < 5; i++ ) {
    NSString *key = [NSString stringWithFormat:@"option%d",i+1];
    UIButton *b = (UIButton*)[self valueForKey:key];
    CGRect oFrame = b.frame;
    [self.originalFrameHash setObject:[NSValue valueWithCGRect:oFrame]
                               forKey:key];
    b.center = CGPointMake(self.view.frame.size.width/2.0,
                           self.view.frame.size.height);
    b.alpha = 0.0;
  }
  
  self.optionDescriptionLabel.layer.cornerRadius = 3.0;
  self.optionDescriptionLabel.text = @"";
  self.optionDescriptionLabel.alpha = 0.0;
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
  
  [self animateIntoPlace];
}

- (void)animateIntoPlace {
  


  [UIView animateWithDuration:0.35 animations:^{
    CGAffineTransform positiveTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:0.0]);
    CGAffineTransform negativeTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:0.0]);
    if ( self.view.frame.origin.x < 0.0 ) {
      positiveTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:45.0]);
      negativeTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:-45.0]);
      self.view.transform = positiveTransform;
      self.view.center = CGPointMake(self.view.center.x+(fabsf(self.view.frame.origin.x)),self.view.center.y);
    }
    if ( self.view.frame.origin.x+self.view.frame.size.width > [[UIScreen mainScreen] bounds].size.width ) {
      positiveTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:-45.0]);
      negativeTransform = CGAffineTransformMakeRotation([Utilities degreesToRadians:45.0]);
      self.view.transform = positiveTransform;
      self.view.center = CGPointMake(self.view.center.x-(fabsf((self.view.frame.origin.x+self.view.frame.size.width)-[[UIScreen mainScreen] bounds].size.width)),self.view.center.y);
    }
    
    self.optionDescriptionLabel.transform = negativeTransform;
    self.optionDescriptionLabel.alpha = 1.0;
    
    for ( unsigned i = 0; i < 5; i++ ) {
      NSString *key = [NSString stringWithFormat:@"option%d",i+1];
      UIButton *b = (UIButton*)[self valueForKey:key];
      NSValue *frame = [self.originalFrameHash objectForKey:key];
      b.frame = [frame CGRectValue];
      b.alpha = 1.0;
      b.transform = negativeTransform;

    }
    

  }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  NSLog(@"Touch Ended");
  [self.delegate pressRemoved];
}

- (void)animateBack {
  
  
  
  [UIView animateWithDuration:0.35 animations:^{

    for ( unsigned i = 0; i < 5; i++ ) {
      NSString *key = [NSString stringWithFormat:@"option%d",i+1];
      UIButton *b = (UIButton*)[self valueForKey:key];
      NSValue *frame = [self.originalFrameHash objectForKey:key];
      b.frame = [frame CGRectValue];
      b.alpha = 0.0;
      b.center = CGPointMake(self.view.frame.size.width/2.0,
                             self.view.frame.size.height);
      b.transform = CGAffineTransformMakeRotation(0.0);
    }
    
    self.optionDescriptionLabel.alpha = 0.0;
    self.optionDescriptionLabel.transform = CGAffineTransformMakeRotation(0.0);
    self.view.transform = CGAffineTransformMakeRotation(0.0);
    
  } completion:^(BOOL finished) {
    [self.view removeFromSuperview];
  }];
}

- (IBAction)optionSelected:(id)sender {
  [[Utilities del] dismissFloatingOptionsMenu];
  
  if ( sender == self.option1 ) {
    [[SocialManager shared] shareWithFacebook:self.sourceableData];
  }
  if ( sender == self.option2 ) {
    [[SocialManager shared] shareWithTwitter:self.sourceableData];
  }
  if ( sender == self.option3 ) {
    //[[SocialManager shared] shareWithLinkedIn:self.sourceableData delegate:nil];
  }
  if ( sender == self.option4 ) {
    //[[SocialManager shared] shareWithEmail:self.sourceableData delegate:nil];
  }
  if ( sender == self.option5 ) {
    // Do nothing for now
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
