//
//  SCPRGrayStripView.h
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRGrayLineView : UIView {
  BOOL _vertical;
  CGFloat _padding;
}

@property BOOL vertical;
@property CGFloat padding;
@property (nonatomic,strong) UIColor *strokeColor;

@end
