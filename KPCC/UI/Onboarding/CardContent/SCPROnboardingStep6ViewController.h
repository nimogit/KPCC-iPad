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
#import "SCPRExternalWebContentViewController.h"


@interface SCPROnboardingStep6ViewController : UIViewController<Cardable,ExternalWebContentDelegate>


@property (nonatomic,strong) IBOutlet UILabel *signingYouInLabel;
@property (nonatomic,strong) NSDictionary *metaData;
@property (nonatomic,strong) ACAccount *account;
@property (nonatomic,weak) id master;
@property (nonatomic,strong) IBOutlet SCPRExternalWebContentViewController *externalWeb;

- (IBAction)buttonTapped:(id)sender;


@end
