//
//  SCPRControllerOverlayAnimator.m
//  KPCC
//
//  Created by John Meeker on 4/29/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "SCPRControllerOverlayAnimator.h"

@implementation SCPRControllerOverlayAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
  return 1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
  UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  [[transitionContext containerView] addSubview:toViewController.view];
  toViewController.view.alpha = 0;
  
  [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
    fromViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    toViewController.view.alpha = 1;
  } completion:^(BOOL finished) {
    fromViewController.view.transform = CGAffineTransformIdentity;
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    
  }];
}

@end
