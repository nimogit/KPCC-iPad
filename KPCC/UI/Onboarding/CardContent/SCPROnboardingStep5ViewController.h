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

@interface SCPROnboardingStep5ViewController : UIViewController<Cardable>


@property (nonatomic,strong) IBOutlet UILabel *signingYouInLabel;
@property (nonatomic,strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic,strong) IBOutlet SCPRSpinnerViewController *spinner;
@property (nonatomic,strong) NSDictionary *metaData;
@property (nonatomic,strong) ACAccount *account;
@property (nonatomic,weak) id master;


- (IBAction)buttonTapped:(id)sender;
- (void)activate;

@end
