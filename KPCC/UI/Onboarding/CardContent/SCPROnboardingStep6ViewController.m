//
//  SCPROnboardingStep2ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep6ViewController.h"
#import "global.h"
#import "SCPRCandidateCell.h"

@interface SCPROnboardingStep6ViewController ()

@end

@implementation SCPROnboardingStep6ViewController

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
  
  self.externalWeb.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {

}

#pragma mark - Cardable
- (void)prepUI {

  self.view.frame = self.view.frame;
  
  NSString *title = self.signingYouInLabel.text;
  
  NSLog(@"Font size before is %1.1f",self.signingYouInLabel.font.pointSize);
  
  [self.signingYouInLabel titleizeText:title
                              bold:NO
                     respectHeight:YES];
  
  NSLog(@"Font size is %1.1f",self.signingYouInLabel.font.pointSize);
  
  self.signingYouInLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(complete)
                                               name:@"logged_in"
                                             object:nil];
  
  [[SocialManager shared] loginWithLinkedIn:self
                                     silent:NO
                                 webcontent:self.externalWeb];

  
  
}

- (void)backTapped {
  
}

#pragma mark - External Web Content
- (void)requestURILoaded:(NSString*)complete {
  NSArray *comps = [complete componentsSeparatedByString:@"="];
  if ( [comps count] > 1 ) {
    NSString *candidate = [comps objectAtIndex:1];
    if ( [candidate rangeOfString:@"access_denied"].location != NSNotFound ) {
      
      
      [[[UIAlertView alloc] initWithTitle:@"Error"
                                  message:@"There was a problem communicating with LinkedIn. Please try again"
                                 delegate:nil
                        cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
      return;
      
    } else {
      

      
      [[SocialManager shared] linkedInTradeCodeForToken:candidate];
    }
  }
}



- (void)continueAuth {
  
}

- (void)complete {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(delayedFinish)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)delayedFinish {
  [(SCPROnboardingFlowViewController *)self.master finish];
}



- (NSInteger)myStepIndex {
  return FlowStepMemberValidateLinkedIn;
}


- (IBAction)buttonTapped:(id)sender {

}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
