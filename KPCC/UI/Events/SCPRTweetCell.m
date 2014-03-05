//
//  SCPRTweetCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRTweetCell.h"

@implementation SCPRTweetCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (NSString*)reuseIdentifier {
  return @"tweet_cell";
}

- (void)prepareForReuse {
  self.twitterImageView.alpha = 0.0;
  self.screenNameLabel.text = @"";
  self.tweetContentLabel.text =  @"";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
