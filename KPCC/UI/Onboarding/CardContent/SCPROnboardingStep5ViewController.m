//
//  SCPROnboardingStep2ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep5ViewController.h"
#import "global.h"
#import "SCPRCandidateCell.h"

@interface SCPROnboardingStep5ViewController ()

@end

@implementation SCPROnboardingStep5ViewController

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

#pragma mark - Cardable
- (void)prepUI {
  
  NSDictionary *meta = (NSDictionary*) [(SCPROnboardingFlowViewController*)self.master cardMetaData];
  self.metaData = meta;
  
  NSString *title = [NSString stringWithFormat:@"Signing in to %@",[meta objectForKey:@"serviceName"]];
  
  [self.signingYouInLabel titleizeText:title
                              bold:NO
                     respectHeight:YES];
  self.signingYouInLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(continueAuth)
                                               name:@"spinner_appeared"
                                             object:nil];
  
  
  
  
  
}

- (void)activate {
  [self.spinner spinInPlaceWithFinishedToken:@"logged_in"];
}

- (void)backTapped {
  
}

- (void)continueAuth {
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self name:@"spinner_appeared"
   object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(finishLogin)
                                               name:@"logged_in"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(fail)
                                               name:@"facebook_fail"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(fail)
                                               name:@"twitter_fail"
                                             object:nil];
  
  ShareIntent type = (ShareIntent)[[self.metaData objectForKey:@"serviceType"] intValue];
  if ( type == ShareIntentTwitter ) {
    self.account = [self.metaData objectForKey:@"extraMeta"];
    [[SocialManager shared] loginWithTwitter:self.account];
  }
  if ( type == ShareIntentFacebook ) {
    [[SocialManager shared] authenticateWithFacebook];
  }
}

- (void)finishLogin {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"facebook_fail"
                                                object:nil];
  
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(delayedFinish)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)fail {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"logged_in"
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"facebook_fail"
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"twitter_fail"
                                                object:nil];
  
  
  [(SCPROnboardingFlowViewController *)self.master popCard];
  
  ShareIntent type = (ShareIntent)[[self.metaData objectForKey:@"serviceType"] intValue];
  NSString *service = @"";
  if ( type == ShareIntentTwitter ) {
    service = @"Twitter";
  }
  if ( type == ShareIntentFacebook ) {
    service = @"Facebook";
  }
  
  [[[UIAlertView alloc] initWithTitle:@"Error"
                              message:[NSString stringWithFormat:@"There was an issue connecting with %@. Please try again in a moment, or try a different sign-in method",service]
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
}

- (void)delayedFinish {
  [(SCPROnboardingFlowViewController *)self.master finish];
}



- (NSInteger)myStepIndex {
  return FlowStepMemberValidateTwitterOrFacebook;
}


- (IBAction)buttonTapped:(id)sender {

}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
