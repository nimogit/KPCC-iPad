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
  
  FXBlurView *blurView = [[FXBlurView alloc] initWithFrame:containerView.frame];
  blurView.blurRadius = 5;
  blurView.tintColor = [UIColor blueColor];
  
  UIView *darkView = [[UIView alloc]initWithFrame:blurView.frame];
  darkView.backgroundColor = [UIColor darkGrayColor];
  
  // Presenting
  if (self.appearing) {
    
    blurView.alpha = 0.0;
    darkView.alpha = 0.0;
    
    [containerView addSubview:blurView];
    [containerView addSubview:darkView];
    
    fromView.userInteractionEnabled = NO;
    
    toView.layer.cornerRadius = 5;
    toView.layer.masksToBounds = YES;
    
    // Set initial scale to 1.5
    toView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    [containerView addSubview:toView];
    

    // Scale down to 90%
    [UIView animateWithDuration:duration animations: ^{
      toView.transform = CGAffineTransformMakeScale(0.9, 0.9);

      darkView.alpha = 0.8;
      
      blurView.alpha = 1.0;
      blurView.blurRadius = 30;

    } completion: ^(BOOL finished) {
      [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
  }
  // Dismissing
  else {
    NSLog(@"Dismissing");
    NSLog(@"fromViews subviews %@", fromView.subviews);
    NSLog(@"toViews subviews %@", toView.subviews);
    NSLog(@"containerView subviews %@", containerView.subviews);
    
    // Locate the FXBlurView and darkview within the containerView subviews if possible
    FXBlurView *blurViewToBeRemoved;
    UIView *darkViewToBeRemoved;
    for (UIView *subview in containerView.subviews) {
      if ([subview isKindOfClass:[FXBlurView class]]) {
        blurViewToBeRemoved = (FXBlurView *) subview;
      }
      
      if (subview.backgroundColor == [UIColor darkGrayColor]) {
        darkViewToBeRemoved = subview;
      }
    }
    
    // Scale down to 0
    [UIView animateWithDuration:duration animations: ^{
      fromView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
      fromView.alpha = 0.0;
      
      // Fade out blur view
      if (blurViewToBeRemoved) {
        blurViewToBeRemoved.alpha = 0.0;
      }

      // Clear out dark background view
      if (darkViewToBeRemoved) {
        [darkViewToBeRemoved setBackgroundColor:[UIColor clearColor]];
      }

    } completion: ^(BOOL finished) {
      [fromView removeFromSuperview];
      if (blurViewToBeRemoved) {
        [blurViewToBeRemoved removeFromSuperview];
      }
      if (darkViewToBeRemoved) {
        [darkViewToBeRemoved removeFromSuperview];
      }
      
      toView.userInteractionEnabled = YES;
      [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
  }
}

@end
