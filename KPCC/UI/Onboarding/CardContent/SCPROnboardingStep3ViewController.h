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


@interface SCPROnboardingStep3ViewController : UIViewController<Cardable>

@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UIButton *memberButton;
@property (nonatomic,strong) IBOutlet UIButton *nopeButton;
@property (nonatomic,strong) IBOutlet UILabel *memberNameLabel;
@property (nonatomic,strong) IBOutlet UILabel *memberIDLabel;
@property (nonatomic,strong) IBOutlet UILabel *verifyIdentityLabel;
@property (nonatomic,strong) IBOutlet UIImageView *avatarImage;

@property (nonatomic,weak) id master;
@property (nonatomic,strong) NSDictionary *memberInfo;


- (IBAction)buttonTapped:(id)sender;


@end
