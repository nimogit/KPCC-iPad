//
//  SCPROnboardingTextField.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPROnboardingTextField.h"

@implementation SCPROnboardingTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (CGRect)textRectForBounds:(CGRect)bounds {
  return [super textRectForBounds:CGRectInset(bounds, 10.0, 2.0)];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  return [super textRectForBounds:CGRectInset(bounds, 10.0, 2.0)];
}

@end
