//
//  SCPRUsefulTransition.m
//  KPCC
//
//  Created by Hochberg, Ben on 10/21/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRUsefulTransition.h"

@implementation SCPRUsefulTransition

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  [super animationDidStop:anim finished:flag];
  [self.delegate finalizeAnimation];
}

@end
