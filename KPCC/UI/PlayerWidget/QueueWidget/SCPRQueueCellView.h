//
//  SCPRQueueCellView.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRQueueCellView : UITableViewCell

@property (nonatomic,strong) id parent;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UILabel *captionLabel;
@property (nonatomic,strong) IBOutlet UILabel *timeLabel;
@property (nonatomic,strong) IBOutlet UILabel *playingBannerLabel;
@property (nonatomic,strong) IBOutlet UIButton *removeButton;
@property (nonatomic,strong) IBOutlet UIImageView *seatedImageView;
@property (nonatomic,strong) IBOutlet UILabel *queuePosition;
- (void)switchOff;

@end
