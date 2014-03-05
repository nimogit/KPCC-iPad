//
//  UIViewController+iOS7Helper.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/26/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "UIViewController+iOS7Helper.h"
#import "Utilities.h"

@implementation UIViewController (iOS7Helper)

- (void)stretch {
  if ( [Utilities isIOS7] ) {
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    UIView *bottomMostView = nil;
    CGFloat yOrigin = 0.0;
    for ( UIView *v in [self.view subviews] ) {
      if ( v.frame.origin.y+v.frame.size.height > yOrigin ) {
        yOrigin = v.frame.origin.y+v.frame.size.height;
        bottomMostView = v;
      }
    }
    
    if ( bottomMostView ) {
      bottomMostView.frame = CGRectMake(bottomMostView.frame.origin.x,
                                        bottomMostView.frame.origin.y,
                                        bottomMostView.frame.size.width,
                                        bottomMostView.frame.size.height+20.0);
    }
  }
}

@end
