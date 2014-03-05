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


@interface SCPROnboardingStep4ViewController : UIViewController<Cardable,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) IBOutlet UITableView *candidateTable;
@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UIButton *nopeButton;
@property (nonatomic,strong) IBOutlet UILabel *whichIsYouLabel;
@property (nonatomic,strong) IBOutlet UILabel *verifyIdentityLabel;

@property (nonatomic,strong) NSDictionary *memberMetaData;
@property (nonatomic,strong) NSArray *memberMetaKeys;

@property (nonatomic,weak) id master;


- (IBAction)buttonTapped:(id)sender;


@end
