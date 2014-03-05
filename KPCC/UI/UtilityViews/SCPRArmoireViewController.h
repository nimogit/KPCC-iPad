//
//  SCPRArmoireViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRArmoireViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIView *contentSeatView;
@property (nonatomic,strong) IBOutlet UIView *gripperView;
@property (nonatomic,strong) IBOutlet UILabel *captionLabel;
@property (nonatomic,strong) UIColor *tintColor;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeToDeploy;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeToRetract;
@property (nonatomic,strong) UITapGestureRecognizer *tapper;

@property (nonatomic,weak) UIView *contentView;
@property (nonatomic,weak) id parent;
@property (nonatomic,weak) UIScrollView *scrollerToDisable;

@property NSInteger style;
@property BOOL deployed;


@end
