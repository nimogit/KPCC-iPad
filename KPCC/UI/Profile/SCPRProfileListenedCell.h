//
//  SCPRProfileListenedCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPRProfileListenedCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayLine;
@property (nonatomic,strong) IBOutlet UILabel *bylineLabel;
@property CGRect originalFrame;

@end
