//
//  SCPRReloadViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRSpinnerViewController.h"

@protocol Reloadable <NSObject>

@required
- (void)reload;
- (NSString*)unfreezeKey;

@end

@interface SCPRReloadViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic,strong) IBOutlet UIView *letterSeat;
@property (nonatomic,strong) IBOutlet UILabel *l1;
@property (nonatomic,strong) IBOutlet UILabel *l2;
@property (nonatomic,strong) IBOutlet UILabel *l3;
@property (nonatomic,strong) IBOutlet UILabel *l4;
@property (nonatomic,strong) IBOutlet UILabel *l5;
@property (nonatomic,strong) IBOutlet UILabel *l6;
@property (nonatomic,weak) UIScrollView *observedScroller;
@property (nonatomic,weak) id<Reloadable> delegate;
@property (nonatomic,strong) NSString *unfreezeKey;
@property (nonatomic,strong) IBOutlet SCPRSpinnerViewController *spinner;

@property BOOL hot;

- (void)setupWithScroller:(UIScrollView*)scroll delegate:(id<Reloadable>)delegate;
- (void)handleReload;

@end
