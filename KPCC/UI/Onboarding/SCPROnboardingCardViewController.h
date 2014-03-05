//
//  SCPROnboardingCardViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPROnboardingFlowViewController.h"

@protocol Cardable <NSObject>


- (void)prepUI;
- (NSInteger)myStepIndex;

@property (nonatomic,weak) id master;

@optional
- (void)backTapped;

@end

@interface SCPROnboardingCardViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIButton *backButton;
@property (nonatomic,strong) IBOutlet UIScrollView *contentScroller;
@property (nonatomic,strong) IBOutlet UIView *cardCrux;
@property (nonatomic,strong) SCPROnboardingFlowViewController *master;
@property (nonatomic,strong) id myCardContent;
@property NSInteger myStepIndex;

- (void)setupWithStep:(FlowStep)step andMaster:(id)master;
- (IBAction)backTapped:(id)sender;

@end
