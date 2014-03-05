//
//  SCPRSegmentCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/27/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRSegmentCell : UITableViewCell


@property (nonatomic,strong) IBOutlet UILabel *segmentTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *segmentDurationLabel;
@property (nonatomic,strong) IBOutlet UIButton *playButton;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,weak) id parentEpisodeCell;
@property (nonatomic,weak) NSDictionary *segment;

- (void)playRequested:(id)sender;

@end
