//
//  AudioManager.m
//  KPCC
//
//  Created by Ben on 4/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "AudioManager.h"
#import "global.h"
#import "SCPRQueueCellViewController.h"

#define kVolumeTick 0.08
#define kSavePointThreshold 120 // 12 seconds

static AudioManager *singleton = nil;

@implementation AudioManager


+ (AudioManager*)shared {
  if ( !singleton ) {
    @synchronized(self) {
      singleton = [[AudioManager alloc] init];
      [singleton prime];
    }
  }
  
  return singleton;
}

- (void)prime {
  self.savedVolume = -1.0;
  self.currentPlayerVolume = 0.5;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(segmentCompleted)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
  
}

- (AVAudioPlayer*)requestAudioPlayer:(NSString*)urlString {
  self.hungryObjects = [[NSMutableArray alloc] init];
  
  return nil;
}

- (void)unlockAudioPlayer:(AVAudioPlayer *)avp {
  [self.apiStreamerPool removeObject:avp];
}

- (void)volumeChanged:(NSNotification*)note {
  
}

#pragma mark - Reporting
- (void)failAudioWithError:(NSString *)error {
  NSLog(@"Audio failing...");
  [[AnalyticsManager shared] analyzeStreamError:error];
  [[AudioManager shared].delegate updateUIforAudioState];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( [keyPath isEqualToString:@"rate"] ) {
    
    CGFloat oldRate = [[change objectForKey:@"old"] floatValue];
    CGFloat newRate = [[change objectForKey:@"new"] floatValue];
    if ( oldRate == 0.0 && newRate == 1.0 ) {
      [self broadcastPlayMessage];
      
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      
    }
  }
}

- (void)watchAudioThroughput:(id)watcher {
  
  @try {
    
    [self.audioPlayer removeObserver:watcher
                          forKeyPath:@"rate"];
    
  } @catch (NSException *e) {
    
  }
  
  [self.audioPlayer addObserver:watcher
                     forKeyPath:@"rate"
                        options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                        context:NULL];
}

- (void)removeWatcher:(id)watcher {
  @try {
    [self.audioPlayer removeObserver:watcher
                          forKeyPath:@"rate"];
  } @catch (NSException *e) {
    
  }
}

- (void)broadcastPlayMessage {
  
  @try {
    [self.audioPlayer removeObserver:self
                          forKeyPath:@"rate"];
  } @catch (NSException *e) {
    
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"player_began_playing"
                                                        object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                        object:nil];
  });
  
}

- (void)segmentCompleted {
  [[QueueManager shared] pop];
}

- (void)mainThreadUpdate {
  [self.delegate updateUIforAudioState];  
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  [self unlockAudioPlayer:player];
}

#pragma mark - AudioPlayer
- (void)buildStreamer:(NSString*)urlForStream {
  
  if ( !urlForStream ) {
    urlForStream = kLiveStreamURL;
  }
  
  [self takedownStreamer];
  
  NSString *sanitized = [Utilities urlize:urlForStream];
  NSURL *url = [NSURL URLWithString:sanitized];
  
  @try {
    [self.audioPlayer removeObserver:self
                          forKeyPath:@"rate"];
  } @catch (NSException *e) {
    // Wasn't necessary
  }
  
  self.audioPlayer = [[AVPlayer alloc] initWithURL:url];
  
  [self.audioPlayer addObserver:self
                       forKeyPath:@"rate"
                          options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                          context:NULL];

  [self armAudioParsingTimer];
}

- (void)takedownStreamer {
  [self disarmAudioParsingTimer];
  [self.audioPlayer removeTimeObserver:self.timeObserver];
  [self.audioPlayer pause];
  self.audioPlayer = nil;
}

- (BOOL)isPlayingOnDemand {
  return [self.audioPlayer.currentItem duration].value > 0.0;
}

- (void)armAudioParsingTimer {

  if ( self.disarmAfterResume ) {
    self.disarmAfterResume = NO;
    
    @try {
      [self.audioPlayer removeObserver:self forKeyPath:@"status"];
    } @catch (NSException *e) {
      // Not armed
    }
  }
  
  if ( self.timeObserver )
    return;
  
  [self disarmAudioParsingTimer];
  __block AudioManager *weakself = self;
  self.timeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 10)
                                                 queue:dispatch_get_main_queue()
                                            usingBlock:^(CMTime time) {
                                              
                                              [weakself updateAudioFrame:nil];
                                              
                                            }];
}

- (void)disarmAudioParsingTimer {
  
  if ( self.timeObserver ) {
    [self.audioPlayer removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
  }
}

- (void)audioPlaybackStateCallback:(NSNotification*)notification {
  if ( self.bootingLiveStream ) {
    self.bootingLiveStream = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter]
       postNotificationName:@"live_stream_started"
       object:nil];
    });
  }
}

- (BOOL)isPlayingAnyAudio {
  return [self.audioPlayer rate] > 0.0;
}

- (void)popQueue {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"pop_queue"
                                                      object:nil];
}

- (void)updateAudioFrame:(NSTimer*)timer {
  
  if ( self.seeking ) {
    return;
  }
  
  if ( self.streamPlaying ) {
    
    if ( self.ticksSinceSave % 10 == 0 ) {
      double currentTotal = [[ContentManager shared].settings totalListeningTime];
      [[ContentManager shared].settings setTotalListeningTime:currentTotal+1.0];
      
    }
    
    AVPlayerItem *ci = self.audioPlayer.currentItem;
    
    if ( !ci || ci.duration.timescale == 0 ) {
      return;
    }
    
    CMTime pcmtime = self.audioPlayer.currentTime;
    
    if ( pcmtime.timescale == 0 ) {
      return;
    }
    
    double duration = ci.duration.value / ci.duration.timescale;
    double progress = pcmtime.value / pcmtime.timescale;
    
    double normalizedTime = 0.0;
    CMTime endTime = CMTimeConvertScale (self.audioPlayer.currentItem.asset.duration,
                                         self.audioPlayer.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
    if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
      normalizedTime = (double) self.audioPlayer.currentTime.value / (double) endTime.value;
    }

    if ( duration > 0.0 ) {
      if ( [[QueueManager shared] currentlyPlayingSegment] ) {
        BOOL commit = self.ticksSinceSave > kSavePointThreshold;
        if ( commit ) {
          self.ticksSinceSave = 0;
        } else {
          self.ticksSinceSave++;
        }
        
        [self.delegate updateTimeText:progress ofDuration:duration];
        
        if ( progress / duration >= 0.5 ) {
          [[QueueManager shared] segmentListenedTo];
        }

        [[QueueManager shared] writeSegmentProgress:normalizedTime commit:commit];
      }
      
      [self.delegate updateScrubber:normalizedTime];
      self.currentStreamSeekTime = normalizedTime;

    } else {
      [self.delegate updateScrubber:1.0];
    }

  }
}


- (void)startStream:(NSString*)streamURL {

  if ( self.savedVolume >= 0.0 ) {
    [self adjustVolume:self.savedVolume];
    self.savedVolume = -1.0;
  }
  
  NSString *finalStream = streamURL;
  
  if ( !finalStream ) {
    finalStream = kLiveStreamURL;
  }
  
  if ( [finalStream isEqualToString:kLiveStreamURL] ) {
    self.streamingContentType = StreamingContentTypeLive;
    self.bootingLiveStream = YES;
    
    [[AnalyticsManager shared] logEvent:@"live_stream_played"
                         withParameters:@{}];
    
    [self.delegate handleLiveStream:YES];
    
    [[QueueManager shared] setCurrentlyPlayingSegment:nil];
    
  } else {
    [self.delegate handleLiveStream:NO];
  }
  
  if ( self.paused ) {
    if ( !self.rebootStream ) {
      [self.audioPlayer pause];
    } else {
      [self buildStreamer:finalStream];
      self.streamPlaying = YES;

      self.audioPlayer.allowsExternalPlayback = YES;
      [self.audioPlayer play];
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
  } else {
    
    [self buildStreamer:finalStream];
    self.streamPlaying = YES;
    
    [self.audioPlayer play];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ( [[QueueManager shared] currentlyPlayingSegment] ) {
      Segment *s = [[QueueManager shared] currentlyPlayingSegment];
      NSNumber *seek = s.seekposition;
      if ( [seek doubleValue] > 0 ) {
        [self seekStream:[s.seekposition doubleValue]];
      }
      
      if ( ![self isPlayingAnyAudio] ) {
        [self.audioPlayer addObserver:self
                           forKeyPath:@"rate"
                              options:NSKeyValueObservingOptionNew
                              context:nil];
      } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                          object:nil];
      }
      
    }
  }
  
  @synchronized(self) {
    self.streamPlaying = YES;
    self.paused = NO;
    self.rebootStream = NO;
  }
  
  self.lastPlayedStreamURLString = finalStream;
  [self.delegate updateUIforAudioState];
  
}

- (void)stopStream {
  [self takedownStreamer];
  self.streamingContentType = StreamingContentTypeLive;
  [self.delegate handleLiveStream:YES];
  [self.delegate updateUIforAudioState];

  @synchronized(self) {
    self.currentStreamSeekTime = 0.0;
    self.streamPlaying = NO;
  }
  
}

- (void)unpauseStream {
  if ( [self paused] ) {
    
    if ( self.savedVolume >= 0.0 ) {
      [self adjustVolume:self.savedVolume];
      self.savedVolume = -1.0;
    }
    
    [self.audioPlayer play];
    @synchronized(self) {
      self.paused = NO;
      self.streamPlaying = YES;
    }
    
    [self.delegate updateUIforAudioState];
  }
}

- (void)pauseStream {

  if ( self.streamPlaying ) {
    [self.audioPlayer pause];
    [[QueueManager shared] writeSegmentProgress:[self.delegate currentScrubberValue]
                                         commit:YES];

    @synchronized(self) {
      self.streamPlaying = NO;
      self.paused = YES;
    }
  }

  if ( [[QueueManager shared] currentlyPlayingSegment] ) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                        object:nil];
  }

  [self.delegate updateUIforAudioState];
}

- (void)seekStream:(double)seekValue {
  if ( seekValue >= 1.0 ) {
    [[QueueManager shared] pop];
    return;
  }

  double cooked = seekValue * self.audioPlayer.currentItem.duration.value;
  
  [[QueueManager shared] writeSegmentProgress:seekValue
                                       commit:YES];
  
  @try {
    [self.audioPlayer seekToTime:CMTimeMake(cooked, self.audioPlayer.currentItem.duration.timescale)];
  } @catch (NSException *e) {
    NSLog(@"Seeking had issues...");
  }
}

- (void)adjustVolume:(CGFloat)volumeLevel {
  if ( volumeLevel < 0.0 ) {
    volumeLevel = 0.5;
  }

  @synchronized(self) {
    self.currentPlayerVolume = volumeLevel;
  }
  
  if ( [Utilities isIOS7] ) {
    [self.audioPlayer setVolume:volumeLevel];
  } else {
    AVAsset *avAsset = [[self.audioPlayer currentItem] asset] ;
    NSArray *audioTracks = [avAsset tracksWithMediaType:AVMediaTypeAudio] ;
    
    NSMutableArray *allAudioParams = [NSMutableArray array] ;
    for(AVAssetTrack *track in audioTracks){
      AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters] ;
      [audioInputParams setVolume:volumeLevel atTime:kCMTimeZero] ;
      [audioInputParams setTrackID:[track trackID]] ;
      [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioVolMix = [AVMutableAudioMix audioMix] ;
    [audioVolMix setInputParameters:allAudioParams];
    [[self.audioPlayer currentItem] setAudioMix:audioVolMix];
  }
}

- (void)pushSilence {
  if ( !self.muted ) {
    self.savedVolume = self.currentPlayerVolume;
    self.muted = YES;
  }
  
  NSLog(@"Saved Volume from push silence is %1.2f",self.savedVolume);
  [self adjustVolume:0.0];
}

- (void)popSilence {
  if ( self.savedVolume >= 0.0 ) {
    [self adjustVolume:self.savedVolume];
    self.savedVolume = -1.0;
  }
}

- (void)handleInterruptSegmentAudio:(NSDictionary *)audioMeta {
  if ( [self isPlayingAnyAudio] ) {
    [self fadeAudio:^{
      NSArray *audioFiles = [audioMeta objectForKey:@"audio"];
      NSDictionary *audioFile = [audioFiles objectAtIndex:0];
      [self.delegate revealCurrentlyPlaying:[audioMeta objectForKey:@"title"]];
      [self startStream:[audioFile objectForKey:@"url"]];
      [self resumeAudio];
    } hard:YES];
  } else {
    NSArray *audioFiles = [audioMeta objectForKey:@"audio"];
    NSDictionary *audioFile = [audioFiles objectAtIndex:0];
    [self.delegate revealCurrentlyPlaying:[audioMeta objectForKey:@"title"]];
    [self startStream:[audioFile objectForKey:@"url"]];
  }
}

- (void)threadedUnfadeAudio:(NSTimer*)timer {
  self.currentPlayerVolume = self.currentPlayerVolume + kVolumeTick;
  BOOL done = NO;
  if ( self.currentPlayerVolume >= self.savedVolume ) {
    self.currentPlayerVolume = self.savedVolume;
    done = YES;
  }
  [self adjustVolume:self.currentPlayerVolume];
  
  if ( done ) {
    self.muted = NO;
    [timer invalidate];
  }
}

- (void)fadeAudio:(AudioFadedCallback)block hard:(BOOL)hard {
  NSLog(@"Fading audio...");
  fadeCallback = block;
  
  self.savedVolume = self.currentPlayerVolume;
  self.muted = YES;
  
  [self adjustVolume:0.0];
  
  dispatch_async(dispatch_get_main_queue(), fadeCallback);
}

- (void)threadedFadeAudio:(NSTimer*)timer {
  self.currentPlayerVolume = self.currentPlayerVolume - kVolumeTick;
  BOOL done = NO;
  if ( self.currentPlayerVolume <= 0.0 ) {
    self.currentPlayerVolume = 0.0;
    done = YES;
  }
  [self adjustVolume:self.currentPlayerVolume];
  
  if ( done ) {
    BOOL hard = [[timer userInfo] boolValue];
    [timer invalidate];
    if ( hard ) {
      [self stopStream];
    } else {
      [self pauseStream];
    }
    dispatch_async(dispatch_get_main_queue(), fadeCallback);
  }
}

- (void)resumeAudio {
  [self startStream:self.lastPlayedStreamURLString];
}

#pragma mark - NSURLConnection
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  int x = 1;
  x++;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@"Error reading stream : %@",[error localizedDescription]);
}

@end
