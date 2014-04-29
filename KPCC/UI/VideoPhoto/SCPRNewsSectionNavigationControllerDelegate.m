//
//  SCPRNewsSectionNavigationControllerDelegate.m
//  KPCC
//
//  Created by John Meeker on 4/29/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import "SCPRNewsSectionNavigationControllerDelegate.h"
#import "SCPRControllerOverlayAnimator.h"
#import "SCPRDeluxeNewsViewController.h"

@interface SCPRNewsSectionNavigationControllerDelegate ()

@property (weak, nonatomic) IBOutlet SCPRDeluxeNewsViewController *deluxeViewController;
@property (strong, nonatomic) SCPRControllerOverlayAnimator* animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition* interactionController;

@end


@implementation SCPRNewsSectionNavigationControllerDelegate

- (void)awakeFromNib
{
  UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  [self.deluxeViewController.view addGestureRecognizer:panRecognizer];
  
  self.animator = [SCPRControllerOverlayAnimator new];
}

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
  UIView* view = self.deluxeViewController.view;
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    CGPoint location = [recognizer locationInView:view];
    if (location.x <  CGRectGetMidX(view.bounds) /*&& self.deluxeViewController.viewControllers.count > 1*/) { // left half
      self.interactionController = [UIPercentDrivenInteractiveTransition new];
      //[self.deluxeViewController popViewControllerAnimated:YES];
    }
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translation = [recognizer translationInView:view];
    CGFloat d = fabs(translation.x / CGRectGetWidth(view.bounds));
    [self.interactionController updateInteractiveTransition:d];
  } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    if ([recognizer velocityInView:view].x > 0) {
      [self.interactionController finishInteractiveTransition];
    } else {
      [self.interactionController cancelInteractiveTransition];
    }
    self.interactionController = nil;
  }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
  if (operation == UINavigationControllerOperationPop) {
    return self.animator;
  }
  //return nil;
  return self.animator;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
  return self.interactionController;
}

@end
