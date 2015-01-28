//
//  SCPROnboardingStep1ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep1ViewController.h"
#import "global.h"

@interface SCPROnboardingStep1ViewController ()

@end

@implementation SCPROnboardingStep1ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark - Cardable
- (void)prepUI {
  
  [self.signInLabel titleizeText:self.signInLabel.text
                            bold:NO
                   respectHeight:YES];
  self.signInLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  [self.blurbLabel titleizeText:self.blurbLabel.text
                           bold:NO
                  respectHeight:YES];
  
  self.blurbLabel.textColor = [[DesignManager shared] darkoalColor];
  
  [self.alreadyMemberLabel titleizeText:self.alreadyMemberLabel.text
                                   bold:NO
                          respectHeight:YES];
  self.alreadyMemberLabel.textColor = [[DesignManager shared] deepOnyxColor];
}

- (void)backTapped {
  
}

- (NSInteger)myStepIndex {
  return FlowStepLanding;
}

- (IBAction)buttonTapped:(id)sender {
  if (sender == self.memberButton) {
    [[AnalyticsManager shared] logEvent:@"single_sign_in"
                         withParameters:@{ @"signOnType" : @"membership" }];
    
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow pushCard:FlowStepMemberInfoInput];
  }

  if (sender == self.twitterButton) {
    [[AnalyticsManager shared] logEvent:@"single_sign_in"
                         withParameters:@{ @"signOnType" : @"twitter" }];
    
    CGRect f2u = [Utilities isIpad] ? self.memberButton.frame : CGRectMake(0.0,
                                                                           self.view.frame.size.height-274.0,
                                                                           self.view.frame.size.width,
                                                                           274.0);
    [[SocialManager shared] handleTwitterInteraction:self
                                    displayedInFrame:f2u];
  }
  
  // -- Developer Note --
  // May 2014: Deprecated signin via LinkedIn
  if (sender == self.linkedinButton) {
    [[AnalyticsManager shared] logEvent:@"single_sign_in"
                         withParameters:@{ @"signOnType" : @"linkedin" }];
    
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow pushCard:FlowStepMemberValidateLinkedIn];
  }
  

  if (sender == self.facebookButton) {
    [[AnalyticsManager shared] logEvent:@"single_sign_in"
                         withParameters:@{ @"signOnType" : @"facebook" }];
    
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow setCardMetaData:@{ @"serviceName" : @"Facebook", @"serviceType" : [NSNumber numberWithInt:ShareIntentFacebook]}];
    [flow pushCard:FlowStepMemberValidateTwitterOrFacebook];
    
  }
}

- (void)activate {
  
}


#pragma mark - Twitterable
- (UIView*)twitterableView {
  return self.view;
}

- (void)currentAccountIdentified:(ACAccount *)account {
  
}

- (void)finishWithAccount:(ACAccount *)account {
  SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
  [flow setCardMetaData:@{ @"serviceName" : @"Twitter", @"serviceType" : [NSNumber numberWithInt:ShareIntentTwitter], @"extraMeta" : account}];
  [flow pushCard:FlowStepMemberValidateTwitterOrFacebook];
}

- (void)twitterAuthenticationFailed {

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
