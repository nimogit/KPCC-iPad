//
//  UIColor+Additions.m
//  KPCC
//
//  Created by Ben Hochberg on 1/14/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor (Additions)

- (UIColor*)translucify:(CGFloat)alpha {
  CGFloat *colorValues = (CGFloat*) CGColorGetComponents(self.CGColor);
  return [UIColor colorWithRed:colorValues[0]
                         green:colorValues[1]
                          blue:colorValues[2]
                         alpha:alpha];
}

+ (UIColor*)virtualBlackColor {
  return [UIColor colorWithRed:1.0/255.0
                         green:1.0/255.0
                          blue:1.0/255.0
                         alpha:1.0];
}

@end
