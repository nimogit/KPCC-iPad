//
//  SCPRShareCellViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"
#import "SCPRShareDrawerCell.h"

@interface SCPRShareCellViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIImageView *logoImage;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *whiteLine;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayLine;
@property (nonatomic,weak) IBOutlet SCPRShareDrawerCell *cellView;
@property (nonatomic,strong) IBOutlet UILabel *captionLabel;
@property (nonatomic,strong) UIImage *repImage;
@property (nonatomic,strong) NSString *shareType;
@property (nonatomic) BOOL disabled;
@property (nonatomic,strong) UIImageView *disabledImage;

@end
