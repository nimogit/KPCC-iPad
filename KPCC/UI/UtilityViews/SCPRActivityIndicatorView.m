//
//  SCPRActivityIndicatorView.m
//  KPCC
//
//  Created by Hochberg, Ben on 7/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRActivityIndicatorView.h"

@implementation SCPRActivityIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)startAnimating {
  [super startAnimating];
  

}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
  UIImage *img = [UIImage imageNamed:@"spinning-donut.png"];
  UIImageView *iv = [[UIImageView alloc] initWithImage:img];
  iv.frame = CGRectMake(0.0,0.0,self.frame.size.width,
                        self.frame.size.height);
  self.color = [UIColor clearColor];
  [self addSubview:iv];
}


@end
