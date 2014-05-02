//
//  SCPRControllerOverlayAnimator.m
//  KPCC
//
//  Created by John Meeker on 4/29/14.
//  Copyright (c) 2014 ;. All rights reserved.
//

#import "SCPRControllerOverlayAnimator.h"

@implementation SCPRControllerOverlayAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
  return 0.4;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
  UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  UIView *fromView = fromVC.view;
  
  UIView *toView = toVC.view;
  UIView *containerView = [transitionContext containerView];
  CGFloat duration = [self transitionDuration:transitionContext];
  
  // Presenting
  if (self.appearing) {
    FXBlurView *blurView = [[FXBlurView alloc] initWithFrame:containerView.frame];
    blurView.blurRadius = 5;
    blurView.tintColor = [UIColor clearColor];
    [containerView addSubview:blurView];
    
    fromView.userInteractionEnabled = NO;
    
    toView.layer.cornerRadius = 5;
    toView.layer.masksToBounds = YES;
    
    // Set initial scale to zero
    toView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    [containerView addSubview:toView];
    

    // Scale up to 90%
    [UIView animateWithDuration:duration animations: ^{
      toView.transform = CGAffineTransformMakeScale(0.9, 0.9);
      fromView.alpha = 0.5;
      blurView.blurRadius = 40;
    } completion: ^(BOOL finished) {
      [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
  }
  // Dismissing
  else {
    NSLog(@"Dismissing");
    
    // Scale down to 0
    [UIView animateWithDuration:duration animations: ^{
      fromView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
      toView.alpha = 1.0;
    } completion: ^(BOOL finished) {
      [fromView removeFromSuperview];
      toView.userInteractionEnabled = YES;
      [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
  }
}

@end
