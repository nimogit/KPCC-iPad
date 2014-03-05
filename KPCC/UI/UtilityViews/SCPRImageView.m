//
//  SCPRImageView.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/5/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRImageView.h"

@implementation SCPRImageView

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

- (void)setImage:(UIImage *)image {
  [super setImage:image];
  
  if ( self.huggingView ) {
    self.actualFrame = [self frameForImage];
  
  
    [[DesignManager shared] avoidNeighborFrame:self.actualFrame
                                    withView:self.huggingView
                                   direction:self.directionRelativeToHuggingView
                                     padding:4.0];
  }
  
}

@end
