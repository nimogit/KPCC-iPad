//
//  SCPRUsefulTransition.h
//  KPCC
//
//  Created by Hochberg, Ben on 10/21/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@protocol AnimationDelegate <NSObject>

- (void)finalizeAnimation;

@end

@interface SCPRUsefulTransition : CATransition


@property (nonatomic,weak) id<AnimationDelegate> animDelegate;
@property (nonatomic,strong) NSString *key;

@end
