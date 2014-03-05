//
//  SCPRBadgeLabel.m
//  KPCC
//
//  Created by Hochberg, Ben on 10/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRBadgeLabel.h"

@implementation SCPRBadgeLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawTextInRect:(CGRect)rect {
  CGRect squished = CGRectMake(rect.origin.x,rect.origin.y-1.0,
                               rect.size.width,rect.size.height);
  [super drawTextInRect:squished];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
