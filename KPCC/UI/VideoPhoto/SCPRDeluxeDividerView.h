//
//  SCPRDeluxeDividerView.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPRDeluxeDividerView : UIView

@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayLine;
@property (nonatomic,strong) IBOutlet UILabel *textLabel;

@end
