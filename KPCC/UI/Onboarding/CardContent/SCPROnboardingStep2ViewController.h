//
//  SCPROnboardingStep1ViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPROnboardingCardViewController.h"
#import "SCPROnboardingTextField.h"
#import "SCPRSpinnerViewController.h"
#import "global.h"

typedef enum {
  TextValidationOK = 0,
  TextValidationBadEmail = 1,
  TextValidationEmailBlank = 2,
  TextValidationLastNameBlank = 3,
  TextValidationZipCodeBlank = 4
} TextValidation;

@interface SCPROnboardingStep2ViewController : UIViewController<Cardable,UITextFieldDelegate,MemberStatusable,UIAlertViewDelegate>

@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UILabel *memberSigninLabel;
@property (nonatomic,strong) IBOutlet UIButton *memberButton;
@property (nonatomic,strong) IBOutlet UILabel *emailLabel;
@property (nonatomic,strong) IBOutlet UILabel *lastNameLabel;
@property (nonatomic,strong) IBOutlet UILabel *zipCodeLabel;
@property (nonatomic,strong) IBOutlet SCPROnboardingTextField *emailTextField;
@property (nonatomic,strong) IBOutlet SCPROnboardingTextField *lastNameTextField;
@property (nonatomic,strong) IBOutlet SCPROnboardingTextField *zipCodeTextField;
@property (nonatomic,weak) SCPROnboardingTextField *currentlyEditing;
@property (nonatomic,strong) IBOutlet UILabel *validatingLabel;
@property (nonatomic,strong) IBOutlet UIView *validatingSeat;
@property (nonatomic,strong) IBOutlet SCPRSpinnerViewController *spinner;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *nSpinner;

@property (nonatomic,weak) id master;


- (IBAction)buttonTapped:(id)sender;
- (void)stylizeTextField:(UITextField*)textField;
- (void)lookForMember;
- (TextValidation)validateInput;
- (void)fail;

@end
