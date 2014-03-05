//
//  SCPRCircleView.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/22/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCircleView.h"
#import "global.h"

@implementation SCPRCircleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    self.backgroundColor = [UIColor clearColor];
  }
  
  return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
  
  CGContextRef cx = UIGraphicsGetCurrentContext();
  CGContextSetFillColor(cx, CGColorGetComponents(self.fillColor.CGColor));
  CGContextFillEllipseInRect(cx, rect);
  
}


@end
