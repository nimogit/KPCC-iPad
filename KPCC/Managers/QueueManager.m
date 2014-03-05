//
//  QueueManager.m
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "QueueManager.h"
#import "global.h"
#import "Segment.h"
#import "SCPRQueueCellViewController.h"
#import "SCPRViewController.h"

static QueueManager *singleton = nil;

@implementation QueueManager

+ (QueueManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[QueueManager alloc] init];
      singleton.queueAssets = [[NSMutableDictionary alloc] init];
      
      [[NSNotificationCenter defaultCenter] addObserver:singleton
                                               selector:@selector(liveStream)
                                                   name:@"changed_to_live_stream"
                                                 object:nil];
    }
  }
  
  return singleton;
}

- (Collection*)queue {
  if ( !_queue ) {
    @synchronized(self) {
      _queue = [[ContentManager shared] createQueue];
    }
  }
  
  return _queue;
}

- (void)liveStream {
  [self setCurrentlyPlayingSegment:nil];
  
  [[AudioManager shared] setStreamingContentType:StreamingContentTypeLive];
  [[AudioManager shared] setRebootStream:YES];
  [[AudioManager shared] startStream:kLiveStreamURL];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                      object:nil];
}

- (void)pop {
  [self removeFromQueueLiteral:self.currentlyPlayingSegment];
  NSArray *a = [[ContentManager shared] orderedSegmentsForCollection:[self queue]];
  
  if ( [a count] > 0 ) {
    Segment *s = [a objectAtIndex:0];
    [self start:s];
  } else {
    
    [self setCurrentlyPlayingSegment:nil];
    [[AudioManager shared] stopStream];
    
  }
  

}

- (void)playSpecificArticle:(id)article {
  
  NSDictionary *trueArticle = nil;
  Segment *s = nil;
  if ( [article isKindOfClass:[Segment class]] ) {
    s = (Segment*)article;
    trueArticle = [s.originalArticle JSONValue];
  } else {
    s = [[ContentManager shared] segmentFromArticle:article];
    trueArticle = (NSDictionary*)article;
  }
  
  if ( ![self articleIsInQueue:trueArticle] ) {
    return;
  }
  
  [self start:s];
}

- (void)setCurrentlyPlayingSegment:(id)currentlyPlayingSegment {
  
  if ( _currentlyPlayingSegment ) {
    
    /*SCPRQueueCellViewController *current = (SCPRQueueCellViewController*)_currentlyPlayingSegment;
     current.relatedSegment.addedToQueueDate = nil;
     
     [[ContentManager shared] removeSegment:current.relatedSegment
     fromCollection:[[QueueManager shared] queue]
     suspendCommit:NO];*/
  }
  
  _currentlyPlayingSegment = currentlyPlayingSegment;
  
  if ( currentlyPlayingSegment ) {
    
    NSDictionary *article = [self.currentlyPlayingSegment.originalArticle JSONValue];
    
    [[[ContentManager shared] settings] setCurrentlyPlaying:[Utilities webstyledSlug:article]];
    
    [[AnalyticsManager shared] logEvent:@"story_being_played"
                         withParameters:[[AnalyticsManager shared] paramsForArticle:article]];
    
    [[ContentManager shared] loadAudioMetaDataForAudio:article];
    
    NSLog(@"Queueing up : %@",[self.currentlyPlayingSegment name]);
  } else {
    
    [[[ContentManager shared] settings] setCurrentlyPlaying:@""];
    [[ContentManager shared] setAudioMetaData:nil];
    
    NSLog(@"Queue is finished");
  }
  
  [[ContentManager shared] setSkipParse:YES];
  [[ContentManager shared] writeSettings];
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                      object:nil];
  
}

- (void)writeSegmentProgress:(double)progress commit:(BOOL)commit {
  if ( self.currentlyPlayingSegment ) {
    self.currentlyPlayingSegment.seekposition = [NSNumber numberWithDouble:progress];
    if ( commit ) {
      [[ContentManager shared] saveContext];
      [[ContentManager shared] setSkipParse:YES];
      [[ContentManager shared] writeSettings];
    }
  }
}

- (void)segmentListenedTo {
  

  Segment *s = self.currentlyPlayingSegment;
  if ( [s.completed boolValue] ) {
    return;
  }
  
  s.completed = [NSNumber numberWithBool:YES];
  
  [[ContentManager shared] saveContextOnMainThread];
  [[ContentManager shared] writeSettings];

}

- (void)addToQueue:(NSDictionary *)article asset:(NSString*)asset {
  
  [self addToQueue:article asset:asset playImmediately:NO];
  
}

- (void)addToQueue:(NSDictionary *)article asset:(NSString*)asset playImmediately:(BOOL)playImmediately {
  
  NSString *sID = @"";
  if ( [article objectForKey:@"id"] && [[article objectForKey:@"id"] rangeOfString:@"external_"].location == NSNotFound ) {
    sID = [article objectForKey:@"id"];
  } else {
    article = [[ContentManager shared] bakeInIDForArticle:article];
    article = [[ContentManager shared] bakeInShortTitleForArticle:article];
    article = [[ContentManager shared] bakeInBylineForArticle:article];
    article = [[ContentManager shared] bakeInThumbnailForArticle:article thumb:asset];
  }
  
  [[AnalyticsManager shared] logEvent:@"article_added_to_queue"
                       withParameters:@{ @"id" : sID }];
  
  NSArray *audio = [article objectForKey:@"audio"];
  if ( [Utilities pureNil:audio] ) {
    if ( [article objectForKey:@"segments"] ) {
      NSArray *segments = [article objectForKey:@"segments"];
      BOOL once = NO;
      BOOL pi = NO;
      for ( NSDictionary *segment in segments ) {
        if ( !once ) {
          once = YES;
          pi = playImmediately;
        }
        NSDictionary *cooked = [[ContentManager shared] bakeInProgramToSegment:segment
                                                                       program:[article objectForKey:@"program"]
                                oid:[article objectForKey:@"id"]];
        [self addToQueue:cooked asset:asset playImmediately:pi];
        pi = NO;
      }
      return;
    }
  }
  
  Segment *s = [[ContentManager shared] segmentFromArticle:article];

  
  if ( playImmediately ) {
    s.queuePosition = 0;
  } else {
    s.queuePosition = [NSNumber numberWithInt:[[[self queue] segments] count]];
  }
  s.addedToQueueDate = [NSDate date];
  
  [[ContentManager shared] addSegment:s
                      toCollection:[self queue]];
  
  NSMutableArray *representation = [self.delegate representation];
  if ( [representation count] == 0 ) {
    [representation addObject:s];
  } else {
    if ( playImmediately ) {
      [representation insertObject:s
                           atIndex:0];
    } else {
      [representation addObject:s];
    }
  }
  
  [self.delegate queueAddedTo];
  
  if ( playImmediately ) {
    [[QueueManager shared] playSpecificArticle:article];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                      object:nil];
  
}

- (void)silentlyAddToQueue:(NSArray *)articles {
  
  for ( unsigned z = 0; z < [articles count]; z++ ) {
    NSDictionary *article = [articles objectAtIndex:z];
    NSString *sID = @"";
    if ( [article objectForKey:@"id"] ) {
      sID = [article objectForKey:@"id"];
    } else {
      article = [[ContentManager shared] bakeInIDForArticle:article];
      article = [[ContentManager shared] bakeInShortTitleForArticle:article];
      article = [[ContentManager shared] bakeInBylineForArticle:article];
    }
    
    [[AnalyticsManager shared] logEvent:@"article_added_to_queue"
                         withParameters:@{ @"id" : sID }];
    
    Segment *s = [[ContentManager shared] segmentFromArticle:article];
    s.queuePosition = [NSNumber numberWithInt:z];
    s.addedToQueueDate = [NSDate date];
    [[ContentManager shared] addSegment:s
                           toCollection:[self queue]];
  }
  
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[ContentManager shared] saveContextOnMainThread];
    [self.delegate queueAddedTo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"five_picked"
                                                        object:nil];
    
  });
}

- (void)pushToQueueLiteral:(id)segment asset:(UIImage *)asset {
  
  Segment *s = (Segment*)segment;
  s.queuePosition = @0;
  s.addedToQueueDate = [NSDate date];
  [[ContentManager shared] addSegment:s
                      toCollection:[self queue]];
  
  [self.delegate queueAddedTo];
  
}

- (void)removeFromQueue:(NSDictionary *)article {
  
  Segment *s = [[ContentManager shared] segmentFromArticle:article];
  s.queuePosition = [NSNumber numberWithInt:-1];
  s.addedToQueueDate = nil;
  s.seekposition = [NSNumber numberWithDouble:0.0];
  
  [self.queueAssets removeObjectForKey:s.slug];
  [[ContentManager shared] removeSegment:s
                       fromCollection:[self queue]];

  
  [self.delegate queueRemovedFrom];
  
  [[ContentManager shared] saveContextOnMainThread];
}

- (void)removeFromQueueLiteral:(id)segment {

  [self silentlyRemoveFromQueue:segment];
  [self.delegate queueRemovedFrom];

  
}

- (void)silentlyRemoveFromQueue:(id)segment {
  Segment *s = (Segment*)segment;
  if ( !s ) {
    return;
  }
  s.queuePosition = [NSNumber numberWithInt:-1];
  s.seekposition = [NSNumber numberWithDouble:0.0];
  s.addedToQueueDate = nil;
  
  if ( ![Utilities pureNil:s.slug] ) {
    [self.queueAssets removeObjectForKey:s.slug];
  }
  
  NSMutableArray *rep = [self.delegate representation];
  if ( [rep containsObject:s] ) {
    [rep removeObject:s];
  }
  
  [[ContentManager shared] removeSegment:s
                          fromCollection:[self queue]
                           suspendCommit:YES];
}

- (BOOL)articleIsInQueue:(NSDictionary *)article {
  return [[ContentManager shared] articleExists:article
                                inCollection:[self queue]];
}

- (BOOL)articleIsPlayingNow:(NSDictionary *)article {
  
  if ( [[AudioManager shared] streamingContentType] == StreamingContentTypeLive ) {
    return NO;
  }
  
  if ( self.currentlyPlayingSegment ) {
    NSDictionary *incumbent = [self.currentlyPlayingSegment.originalArticle JSONValue];
    
    if ( ![article objectForKey:@"id"] ) {
      article = [[ContentManager shared] bakeInIDForArticle:article];
    }
    NSString *title = [article objectForKey:@"id"];
    NSString *playingTitle = [incumbent objectForKey:@"id"];
    if ( [[Utilities sha1:title] isEqualToString:[Utilities sha1:playingTitle]] ) {
      return YES;
    } else {
      if ( [article objectForKey:@"parent_id"] ) {
        if ( [[Utilities sha1:[article objectForKey:@"parent_id"]] isEqualToString:[Utilities sha1:playingTitle]] ) {
          return YES;
        }
      }
    }
  }
          
  return NO;
}

- (void)start:(id)segment {
  self.queuePlaying = YES;
  
  
  Segment *cp = [[QueueManager shared] currentlyPlayingSegment];
  Segment *requested = (Segment*)segment;
  
  NSDictionary *requestedArticle = [requested.originalArticle JSONValue];
  NSDictionary *cpArticle = [cp.originalArticle JSONValue];
  
  
  NSString *title = [requestedArticle objectForKey:@"short_title"];
  if ( [Utilities pureNil:title] ) {
    title = [requestedArticle objectForKey:@"title"];
  }
  
  if ( ![Utilities article:requestedArticle isSameAs:cpArticle] || !cp ) {
    
    [[QueueManager shared] setCurrentlyPlayingSegment:requested];
    [[AudioManager shared] setStreamingContentType:StreamingContentTypeOnDemand];
    [[AudioManager shared] setRebootStream:YES];
    
    double seek = [requested.seekposition doubleValue];
    NSLog(@"Seek is %1.2f",seek);
    
    [[AudioManager shared] startStream:requested.url];
  }
  
}

- (void)handleInterruption:(CGFloat)currentTime {
  if ( self.currentlyPlayingSegment ) {
    self.queuePlaying = NO;
    
    [[ContentManager shared] saveContextOnMainThread];
    
    self.interruptionTime = currentTime;
  }
}

- (void)pluckFiveAndAddToQueue {
  
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
    NSMutableArray *segments = [[NSMutableArray alloc] init];
    NSMutableDictionary *cloneHash = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *general = [self.stories objectForKey:@"general"];

    
    
    if ( [segments count] < 5 ) {
      for ( unsigned j = 0; j < [general count]; j++ ) {
        NSDictionary *story = [general objectAtIndex:j];
        NSArray *audio = [story objectForKey:@"audio"];
        if ( [audio count] > 0 ) {
          NSString *cloneKey = [Utilities sha1:[story objectForKey:@"short_title"]];
          if ( [cloneHash objectForKey:cloneKey] ) {
            continue;
          }
          [cloneHash setObject:@1 forKey:cloneKey];
          
          [segments addObject:story];
          if ( [segments count] >= 5 ) {
            break;
          }
        }

      }
    }
    
    if ( [segments count] == 0 ) {
      // Let's hope this NEVER happens
      NSLog(@" ************* NO AUDIO FOUND FOR PICK FIVE **************** ");
      dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.delegate queueAddedTo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"five_picked"
                                                            object:nil];
      });
    } else {
      
      [self silentlyAddToQueue:segments];
      
    }

  });
  


}

- (BOOL)queueIsEmpty {
  return [[[self queue] segments] count] == 0;
}

@end
