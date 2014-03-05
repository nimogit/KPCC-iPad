//
//  SCPRShadowingView.h
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRShadowingView : UIView

- (void)attachToView:(UIView*)view managedBy:(UIView*)parentView;

@property (nonatomic,weak) IBOutlet UIView *viewToShadow;
@property (nonatomic,weak) UIView *parentView;
@property BOOL armed;

@end
