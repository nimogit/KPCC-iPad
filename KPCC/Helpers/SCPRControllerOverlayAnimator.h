//
//  SCPRControllerOverlayAnimator.h
//  KPCC
//
//  Created by John Meeker on 4/29/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//
#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import "FXBlurView.h"

@interface SCPRControllerOverlayAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isAppearing) BOOL appearing;

@end
