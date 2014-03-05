//
//  SCPRDrawerSectionHeaderView.h
//  KPCC
//
//  Created by Hochberg, Ben on 7/17/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPRDrawerSectionHeaderView : UIView

@property (nonatomic,strong) IBOutlet UILabel *sectionCaptionLabel;
@property (nonatomic,strong) IBOutlet UIImageView *sectionIconImageView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *topLine;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *bottomLine;

@end
