//
//  SCPRSnapshotCell.h
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPRSnapshotCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UIView *containerView;
@property (nonatomic,strong) IBOutlet UIImageView *articleImage;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UILabel *publishedAtLabel;
@property (nonatomic,strong) IBOutlet UIImageView *sourceImage;
@property (nonatomic,strong) IBOutlet UIView *cloak;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *divider;

@property NSInteger index;

- (void)animateCard;
- (void)cloakCard;

@end
