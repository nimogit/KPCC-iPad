//
//  SCPRGrayStripView.m
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRGrayStripView.h"
#import "global.h"

@implementation SCPRGrayStripView

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
    //self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientPattern.png"]];
    
    /*
    UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0.0,0.0,
                                                                       self.frame.size.width,
                                                                       self.frame.size.height)];
    image.contentMode = UIViewContentModeRedraw;
    image.image = [UIImage imageNamed:@"gradientPattern2.png"];
    [self addSubview:image];
    [self sendSubviewToBack:image];*/
    
  }
  
  return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*- (void)drawRect:(CGRect)rect
{
 
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetStrokeColor(context, CGColorGetComponents([[DesignManager shared] number1pencilColor].CGColor));
  CGContextSetLineWidth(context, 1.0);
  CGContextMoveToPoint(context, 0.0, 1.0);
  CGContextAddLineToPoint(context, self.frame.size.width, 1.0);
  
  CGContextMoveToPoint(context, 0.0, self.frame.size.height-1.0);
  CGContextAddLineToPoint(context, self.frame.size.width, 1.0);
  
  CGContextStrokePath(context);
  
  CGContextSetStrokeColor(context, CGColorGetComponents([UIColor whiteColor].CGColor));
  CGContextSetFillColor(context, CGColorGetComponents([[DesignManager shared] touchOfGrayColor].CGColor));
  
  CGRect verticalSquish = CGRectInset(rect, 0.0, 2.0);
  CGContextAddRect(context, verticalSquish);
  
  CGContextFillRect(context, verticalSquish);
  
}*/


@end
