//
//  SCPRFlatShadedButton.h
//  KPCC
//
//  Created by Ben Hochberg on 5/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRFlatShadedButton : UIButton

@property (nonatomic,strong) UIColor *shadeColor;
@property BOOL special;

- (void)prime;

@end
