//
//  SCPRGrayStripView.m
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRGrayLineView.h"
#import "global.h"

@implementation SCPRGrayLineView

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
 

  self.backgroundColor = [UIColor clearColor];
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  if ( self.strokeColor ) {
    CGContextSetStrokeColor(context, CGColorGetComponents(self.strokeColor.CGColor));
  } else {
    CGContextSetStrokeColor(context, CGColorGetComponents([[DesignManager shared] number1pencilColor].CGColor));
  }
  CGContextSetLineWidth(context, 1.0);
  
  if ( !self.vertical ) {

    CGContextMoveToPoint(context, self.padding, rect.size.height/2.0);
    CGContextAddLineToPoint(context, self.frame.size.width-self.padding, rect.size.height/2.0);
  
  } else {
    
    CGContextMoveToPoint(context, rect.size.width/2.0, self.padding);
    CGContextAddLineToPoint(context, rect.size.width/2.0, self.frame.size.height-self.padding);
  }
  
  CGContextStrokePath(context);
  
  
}

- (void)setStrokeColor:(UIColor *)strokeColor {
  _strokeColor = strokeColor;
  [self setNeedsDisplay];
}

@end
