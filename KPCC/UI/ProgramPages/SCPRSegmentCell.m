//
//  SCPRSegmentCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/27/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSegmentCell.h"
#import "global.h"
#import "SCPRProgramCell.h"
#import "SCPRProgramPageViewController.h"

@implementation SCPRSegmentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)playRequested:(id)sender {
  
  self.spinner.color = [[DesignManager shared] periwinkleColor];
  [UIView animateWithDuration:0.12 animations:^{
    self.spinner.alpha = 1.0;
    [self.spinner startAnimating];
    self.playButton.alpha = 0.0;
  } completion:^(BOOL finished) {
    NSDictionary *segment = self.segment;
    
    if ( [[QueueManager shared] articleIsInQueue:segment] ) {
      
      [[QueueManager shared] playSpecificArticle:segment];

      [[AnalyticsManager shared] logEvent:@"program_segment_played"
                           withParameters:@{@"program_title" : [((SCPRProgramPageViewController*)((SCPRProgramCell*) self.parentEpisodeCell).parentController).programObject objectForKey:@"title"]}];
      
    } else {
      
      SCPRProgramCell *cell = (SCPRProgramCell*)self.parentEpisodeCell;
      SCPRProgramPageViewController *ppvc = (SCPRProgramPageViewController*)cell.parentController;
      
      NSString *asset = [ppvc imageNameForProgram];
      [[QueueManager shared] addToQueue:segment
                                  asset:asset
                        playImmediately:![[AudioManager shared] isPlayingAnyAudio]];
      
    }
  }];

}

- (NSString*)reuseIdentifier {
  return @"segment_cell";
}

@end
