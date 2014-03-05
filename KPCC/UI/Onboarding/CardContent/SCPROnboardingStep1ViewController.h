//
//  SCPROnboardingStep1ViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPROnboardingCardViewController.h"
#import "global.h"

@interface SCPROnboardingStep1ViewController : UIViewController<Cardable,Twitterable>

@property (nonatomic,strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UILabel *alreadyMemberLabel;
@property (nonatomic,strong) IBOutlet UILabel *orLabel;
@property (nonatomic,strong) IBOutlet UIButton *memberButton;
@property (nonatomic,strong) IBOutlet UIButton *facebookButton;
@property (nonatomic,strong) IBOutlet UIButton *twitterButton;
@property (nonatomic,strong) IBOutlet UIButton *linkedinButton;
@property (nonatomic,strong) IBOutlet UILabel *signInLabel;
@property (nonatomic,weak) id master;

- (IBAction)buttonTapped:(id)sender;

@end
