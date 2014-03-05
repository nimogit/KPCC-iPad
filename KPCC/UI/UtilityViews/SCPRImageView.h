//
//  SCPRImageView.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/5/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@interface SCPRImageView : UIImageView

@property (nonatomic) CGRect actualFrame;
@property (nonatomic,strong) UIView *huggingView;
@property NeighborDirection directionRelativeToHuggingView;

@end
