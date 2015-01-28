//
//  SCPROnboardingStep2ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep3ViewController.h"
#import "global.h"

@interface SCPROnboardingStep3ViewController ()

@end

@implementation SCPROnboardingStep3ViewController

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
  
  NSArray *meta = (NSArray*)[(SCPROnboardingFlowViewController*)self.master cardMetaData];
  NSDictionary *only = [meta objectAtIndex:0];
  self.memberInfo = only;
  
  [[ContentManager shared].settings setMemberInformation:[self.memberInfo JSONRepresentation]];
  
  NSString *memberString = [NSString stringWithFormat:@"Member ID: %@",[only objectForKey:@"member_id"]];
  [self.memberIDLabel titleizeText:memberString
                                  bold:NO
                         respectHeight:YES];
  
  self.memberIDLabel.textColor = [[DesignManager shared] number3pencilColor];
  
  [self.verifyIdentityLabel titleizeText:self.verifyIdentityLabel.text
                              bold:NO
                     respectHeight:YES];
  self.verifyIdentityLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  
  [self.blurbLabel titleizeText:self.blurbLabel.text
                           bold:NO
                  respectHeight:YES];
  
  self.blurbLabel.textColor = [[DesignManager shared] darkoalColor];
  
  [self.memberNameLabel titleizeText:[(NSString*)[only objectForKey:@"member_name"] uppercaseString]
                              bold:NO
                     respectHeight:YES];
  
  self.memberNameLabel.textColor = [[DesignManager shared] deepOnyxColor];
  

  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.nopeButton.titleLabel.font.pointSize]
                                forButton:self.nopeButton];
  
  [[SocialManager shared] memberImageTo:self.avatarImage];
  
}

- (void)activate {
  
}

- (NSInteger)myStepIndex {
  return FlowStepMemberValidateSingle;
}

- (void)backTapped {
  [[ContentManager shared].settings setMemberInformation:@""];
}

- (IBAction)buttonTapped:(id)sender {
  SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
  if ( sender == self.nopeButton ) {
    [[ContentManager shared].settings setMemberInformation:@""];
    [flow popCard];
  }
  if ( sender == self.memberButton ) {
    [[SocialManager shared] loginWithMembershipInfo:self.memberInfo];
    [flow finish];
  }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
