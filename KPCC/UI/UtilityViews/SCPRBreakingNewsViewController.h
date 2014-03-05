//
//  SCPRBreakingNewsViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

typedef void (^BreakingInteractionCallback)(void);

@interface SCPRBreakingNewsViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIView *cardView;
@property (nonatomic,strong) IBOutlet UIView *cardContentView;
@property (nonatomic,strong) IBOutlet UILabel *breakingHeadlineLabel;
@property (nonatomic,strong) IBOutlet UIView *categorySeat;
@property (nonatomic,strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic,strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic,strong) IBOutlet UIView *redStripeView;
@property (nonatomic,strong) UISwipeGestureRecognizer *swiper;
@property (nonatomic,strong) UIButton *interactionButton;
@property (nonatomic,strong) BreakingInteractionCallback action;

- (void)showOnView:(UIViewController*)viewController withMessage:(NSString*)message action:(BreakingInteractionCallback)action;
- (void)showOnView:(UIViewController*)viewController withMessage:(NSString*)message actionOnDismiss:(BOOL)actionOnDismiss action:(BreakingInteractionCallback)action;
- (void)hide;

@property BOOL showing;
@property BOOL actionOnDismiss;

@end
