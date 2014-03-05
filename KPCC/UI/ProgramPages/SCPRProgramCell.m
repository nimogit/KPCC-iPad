//
//  SCPRProgramCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/26/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProgramCell.h"
#import "SCPRSegmentCell.h"
#import "SCPRProgramPageViewController.h"

#import "global.h"

@implementation SCPRProgramCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refresh)
                                                 name:@"notify_listeners_of_queue_change"
                                               object:nil];*/
  }
  
  return self;
}

- (void)prepareForReuse {
  [self.actionButton removeTarget:self.parentController
                           action:@selector(playRequested:)
                 forControlEvents:UIControlEventTouchUpInside];
  self.episodeTitleLabel.frame = self.originalHeadlineFrame;
  self.numberOfSegmentsLabel.frame = self.originalSegmentsLabelFrame;
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)bringUpFloatingMenu:(UIGestureRecognizer*)gr {
  
  /*UILongPressGestureRecognizer *lpgr = (UILongPressGestureRecognizer*)gr;
  CGPoint tpiv = [lpgr locationOfTouch:0 inView:self];
  
  [self.actionButton setHighlighted:NO];
  
  [[Utilities del] presentFloatingOptionsMenuFromPoint:tpiv
                                            sourceView:self
                                              delegate:self
                                            withObject:[Utilities convertToArticle:self.programEpisode]];*/
}


- (void)mainPlayRequested:(id)sender {
  
  if ( [[QueueManager shared] articleIsPlayingNow:self.programEpisode] ) {
    return;
  }
  
  [UIView animateWithDuration:0.1 animations:^{
    [self.spinner startAnimating];
    [self.actionButton setAlpha:0.0];
    [self.spinner setAlpha:1.0];
  } completion:^(BOOL finished) {
    
    SCPRProgramPageViewController *ppvc = (SCPRProgramPageViewController*)self.parentController;
    [ppvc playRequested:self.actionButton];
  }];
}

- (IBAction)playRequested:(id)sender {
  

  


}

- (void)refresh {

  [self.segmentsTable reloadData];
  
}

#pragma mark - OptionsDelegate
- (void)pressRemoved {
  [[Utilities del] dismissFloatingOptionsMenu];
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.segments count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  SCPRSegmentCell *segmentCell = [self.segmentsTable dequeueReusableCellWithIdentifier:@"segment_cell"];
  NSDictionary *segment = [self.segments objectAtIndex:indexPath.row];
  
  if ( [[QueueManager shared] articleIsInQueue:segment] ) {
    if ( [[QueueManager shared] articleIsPlayingNow:segment] ) {
      [[DesignManager shared] globalSetImageTo:@"now_playing_button.png"
                                     forButton:segmentCell.playButton];
    } else {
      [[DesignManager shared] globalSetImageTo:@"in_queue_button.png"
                                     forButton:segmentCell.playButton];
    }
  } else {
    [[DesignManager shared] globalSetImageTo:@"play_now_button.png"
                                   forButton:segmentCell.playButton];
  }
  
  if ( !segmentCell ) {
    segmentCell = [Utilities loadNib:@"SCPRSegmentCell"];
  }
  

  [segmentCell.segmentTitleLabel titleizeText:[segment objectForKey:@"title"]
                                        bold:NO
                               respectHeight:YES
                                      lighten:YES];


  NSArray *audio = [segment objectForKey:@"audio"];
  if ( [audio count] > 0 ) {
    NSDictionary *audioInfo = [audio objectAtIndex:0];
    id duration = [audioInfo objectForKey:@"duration"];
    if ( ![Utilities pureNil:duration] ) {
      [segmentCell.segmentDurationLabel italicizeText:[Utilities formalStringFromSeconds:[[audioInfo objectForKey:@"duration"] intValue]]
                                           bold:YES
                                  respectHeight:YES];
    } else {
      segmentCell.segmentDurationLabel.alpha = 0.0;
      segmentCell.playButton.alpha = 0.0;
    }
  } else {
    segmentCell.segmentDurationLabel.alpha = 0.0;
    segmentCell.playButton.alpha = 0.0;
  }
  
  segmentCell.playButton.tag = indexPath.row;
  segmentCell.parentEpisodeCell = self;
  segmentCell.spinner.alpha = 0.0;
  segmentCell.playButton.alpha = 1.0;
  segmentCell.segment = segment;
  
  [segmentCell.playButton addTarget:segmentCell
                             action:@selector(playRequested:)
                   forControlEvents:UIControlEventTouchUpInside];
  
  segmentCell.segmentDurationLabel.textColor = [[DesignManager shared] number2pencilColor];
  
  // TODO: Make these real objects
  segmentCell.selectionStyle = UITableViewCellSelectionStyleNone;
  
 
    [[DesignManager shared] avoidNeighbor:segmentCell.segmentTitleLabel
                               withView:segmentCell.segmentDurationLabel
                              direction:NeighborDirectionAbove
                                padding:3.0];
  
  
  
  return segmentCell;

}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRSegmentCell"]
                                                   owner:nil
                                                 options:nil];
  UIView *v = (SCPRProgramCell*)[objects objectAtIndex:1];
  UILabel *textLabel = (UILabel*)[v viewWithTag:kHeaderLabelTag];

  [textLabel thickerText:@"SEGMENTS FROM THIS EPISODE"
                      bold:NO
             respectHeight:YES];
  textLabel.textColor = [[DesignManager shared] number2pencilColor];
  
  
  v.backgroundColor = [[DesignManager shared] stratusCloudColor:1.0];
  
  return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRSegmentCell *segmentCell = [Utilities loadNib:@"SCPRSegmentCell"];
  return segmentCell.frame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  NSArray *objects = [[NSBundle mainBundle] loadNibNamed:[[DesignManager shared]
                                                          xibForPlatformWithName:@"SCPRSegmentCell"]
                                                   owner:nil
                                                 options:nil];
  UIView *v = (SCPRProgramCell*)[objects objectAtIndex:1];
  return v.frame.size.height;
}



- (NSString*)reuseIdentifier {
  return @"episode_cell";
}

@end
