//
//  SCPRQueueCellView.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRQueueCellView.h"
#import "SCPRQueueCellViewController.h"
#import "global.h"

@implementation SCPRQueueCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)switchOff {
  self.parent = nil;
}

- (void)prepareForReuse {
  SCPRQueueCellViewController *qcv = (SCPRQueueCellViewController*)self.parent;
  [qcv unhook];
  
  qcv.timeLabel.alpha = 1.0;
  
  self.headlineLabel.frame = qcv.originalHeadlineFrame;
  self.captionLabel.frame = qcv.originalCaptionFrame;
  
}

- (NSString*)reuseIdentifier {
  return @"queue_cell";
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
