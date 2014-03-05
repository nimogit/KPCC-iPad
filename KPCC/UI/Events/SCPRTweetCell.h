//
//  SCPRTweetCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRTweetCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel *screenNameLabel;
@property (nonatomic,strong) IBOutlet UILabel *tweetContentLabel;
@property (nonatomic,strong) IBOutlet UIImageView *twitterImageView;

@end
