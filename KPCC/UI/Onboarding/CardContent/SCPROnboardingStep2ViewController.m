//
//  SCPROnboardingStep2ViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingStep2ViewController.h"
#import "global.h"
#import "SCPRViewController.h"

@interface SCPROnboardingStep2ViewController ()

@end

@implementation SCPROnboardingStep2ViewController

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
  
  self.validatingSeat.alpha = 0.0;
  self.nSpinner.color = [[DesignManager shared] turquoiseCrystalColor:1.0];
  
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Cardable
- (void)prepUI {
  [self.memberSigninLabel titleizeText:self.memberSigninLabel.text
                                  bold:NO
                         respectHeight:YES];
  self.memberSigninLabel.textColor = [[DesignManager shared] kpccOrangeColor];
  
  [self stylizeTextField:self.emailTextField];
  [self stylizeTextField:self.lastNameTextField];
  [self stylizeTextField:self.zipCodeTextField];
  
  self.zipCodeTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
  self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
  
  [self.blurbLabel titleizeText:self.blurbLabel.text
                           bold:NO
                  respectHeight:YES];
  
  self.blurbLabel.textColor = [[DesignManager shared] darkoalColor];
  self.validatingLabel.textColor = [[DesignManager shared] periwinkleColor];
  [self.validatingLabel titleizeText:self.validatingLabel.text
                                bold:NO];
  
  [self.emailLabel titleizeText:self.emailLabel.text bold:NO];
  [self.lastNameLabel titleizeText:self.lastNameLabel.text bold:NO];
  [self.zipCodeLabel titleizeText:self.zipCodeLabel.text bold:NO];
  
#ifdef DEBUG
  self.emailTextField.text = @"adroitprimate@gmail.com";
  self.zipCodeTextField.text = @"91030";
  self.lastNameTextField.text = @"Dillingham";
#endif
}

- (void)activate {
  
}

- (NSInteger)myStepIndex {
  return FlowStepMemberInfoInput;
}

- (void)stylizeTextField:(UITextField *)textField {
  textField.backgroundColor = [UIColor clearColor];
  textField.layer.borderWidth = 1.0;
  textField.layer.cornerRadius = 3.0;
  textField.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  textField.delegate = self;
  textField.font = [[DesignManager shared] latoRegular:24.0];
  textField.returnKeyType = UIReturnKeyGo;
  textField.enablesReturnKeyAutomatically = YES;
  [(SCPROnboardingTextField*)textField setNeedsDisplay];
}

- (IBAction)buttonTapped:(id)sender {
  if ( self.currentlyEditing ) {
    [self.currentlyEditing resignFirstResponder];
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow snapRubberBand];
    [self lookForMember];
    return;
  } else {
    [self lookForMember];
  }
}

- (void)lookForMember {
  // Do nothing for now
  /*[[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(beginMemberVerification:)
   name:@"spinner_appeared"
   object:nil];
  
  [self.spinner spinInPlaceWithFinishedToken:@"membership_validated"];*/
  [self beginMemberVerification:nil];
  
}

- (void)beginMemberVerification:(NSNotification*)note {
  
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(validateResult:)
   name:@"membership_validated"
   object:nil];
  
  [self.nSpinner startAnimating];
  
  [UIView animateWithDuration:0.44 animations:^{
    self.validatingSeat.alpha = 1.0;
    self.memberButton.alpha = 0.0;
  } completion:^(BOOL finished) {
    
    [[SocialManager shared] validateMembershipWithKeys:@{ @"email" : self.emailTextField.text,
                                                          @"last_name" : self.lastNameTextField.text,
                                                          @"zip" : self.zipCodeTextField.text}
                                              delegate:self];
    
  }];
}

- (void)validateResult:(NSNotification*)note {
  
  
  NSNumber *key = [note object];
  if ( key ) {
    
    [self fail];
    
  } else {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:@"membership_validated"
     object:nil];
  }
}

- (void)fail {
  
  [[SocialManager shared] setMemberEmailCandidate:@""];
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self
   name:@"membership_validated"
   object:nil];
  
  [UIView animateWithDuration:0.44 animations:^{
    self.validatingSeat.alpha = 0.0;
    self.memberButton.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    UIAlertView *error = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"We were unable to find a match in our membership database. Double check the information you entered and try again"
                                                   delegate:self
                                          cancelButtonTitle:@"Contact Us"
                                          otherButtonTitles:@"OK", nil];
    [error show];
    
  }];
}

#pragma mark - MemberStatusable
- (void)processMemberData:(NSArray *)meta {
  
  [self.nSpinner stopAnimating];
  
  [[NSNotificationCenter defaultCenter]
   removeObserver:self
   name:@"membership_validated"
   object:nil];
  
  if ( !meta || [meta count] == 0 ) {
    [self fail];
    return;
  }
  
  
  NSMutableDictionary *foundHash = [[NSMutableDictionary alloc] init];
  for ( NSDictionary *d in meta ) {
    NSString *mid = [d objectForKey:@"member_id"];
    if ( [foundHash objectForKey:mid] ) {
      continue;
    }
    
    NSMutableDictionary *md = [d mutableCopy];
    if ( [[SocialManager shared] memberEmailCandidate] ) {
      [md setObject:[[SocialManager shared] memberEmailCandidate]
             forKey:@"email"];
    }
    [foundHash setObject:md forKey:mid];
  }
  
  meta = [foundHash allValues];
  
  [UIView animateWithDuration:0.44 animations:^{
    self.validatingSeat.alpha = 0.0;
    self.memberButton.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    
    NSArray *memberData = meta;
    
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow setCardMetaData:memberData];
    
    if ( [memberData count] > 1 ) {
      [flow pushCard:FlowStepMemberValidateMultiple];
    } else {
      [flow pushCard:FlowStepMemberValidateSingle];
    }
    
  }];
}

- (void)backTapped {

}

#pragma mark - UITextField
- (void)textFieldDidBeginEditing:(UITextField *)textField {
  SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
  
  CGFloat offset = [Utilities isLandscape] ? 220.0 : 100.0;
  
  [flow rubberBandCard:offset responder:textField];
  self.currentlyEditing = (SCPROnboardingTextField*)textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ( [self validateInput] == TextValidationOK ) {
    [textField resignFirstResponder];
    SCPROnboardingFlowViewController *flow = (SCPROnboardingFlowViewController*)self.master;
    [flow snapRubberBand];
    [self lookForMember];
    return YES;
  }
  
  return NO;
}

- (TextValidation)validateInput {
  return TextValidationOK;
}
#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"Deallocating Step2 View Controller");
}
#endif

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if ( buttonIndex == 0 ) {
    [[[Utilities del] viewController] primeUI:ScreenContentTypeFeedback newsPath:@""];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
