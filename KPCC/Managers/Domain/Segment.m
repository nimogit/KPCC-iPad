//
//  Segment.m
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "Segment.h"
#import "Collection.h"
#import "Keyword.h"
#import "QueueManager.h"

@implementation Segment

@dynamic airdate;
@dynamic duration;
@dynamic name;
@dynamic seekposition;
@dynamic url;
@dynamic slug;
@dynamic collections;
@dynamic keywords;
@dynamic addedToQueueDate;
@dynamic thumbnail;
@dynamic originalArticle;
@dynamic queuePosition;
@dynamic completed;
@dynamic program;

- (BOOL)isCurrentlyPlaying {
  
  Segment *s = [[QueueManager shared] currentlyPlayingSegment];
  if ( s ) {
    
    if ( [s.name isEqualToString:self.name] ) {
      return YES;
    }
    
  }
  
  return NO;
  
}

@end
