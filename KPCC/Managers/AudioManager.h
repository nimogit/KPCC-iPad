//
//  AudioManager.h
//  KPCC
//
//  Created by Ben on 4/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioStreamer.h"
#import <AVFoundation/AVFoundation.h>

typedef void (^AudioFadedCallback)(void);

#ifdef IPAD_VERSION
#define kLiveStreamURL @"http://live.scpr.org/kpcclive?ua=SCPRIPAD"
#else
#define kLiveStreamURL @"http://live.scpr.org/kpcclive?ua=SCPRIPHONE"
#endif

//#define kLiveStreamURL @"http://66.226.4.238:8015/aac"

typedef enum {
  StreamingContentTypeUnknown = 0,
  StreamingContentTypeLive = 1,
  StreamingContentTypeOnDemand = 2,
  StreamingContentTypeInterrupt = 3
} StreamingContentType;

@protocol AudioManagerDelegate <NSObject>

- (void)updateScrubber:(double)progress;
- (void)disableScrubber;
- (void)enableScrubber;
- (void)updateUIforAudioState;
- (void)handleLiveStream:(BOOL)live;
- (void)revealCurrentlyPlaying:(NSString*)title;
- (void)updateTimeText:(double)progress ofDuration:(double)duration;
- (CGFloat)currentScrubberValue;

@end


@interface AudioManager : NSObject<AVAudioPlayerDelegate> {
  
  AudioStreamer *_audioStreamer;
  NSMutableArray *_apiStreamerPool;
  NSMutableDictionary *_apiStreamerLocks;
  
  NSTimer *_audioParsingTimer;
  NSString *_lastPlayedStreamURLString;
  
  BOOL _streamPlaying;
  BOOL _localPlaying;
  BOOL _paused;
  BOOL _seeking;
  BOOL _rebootStream;
  BOOL _fadeRequested;
  BOOL _playingQueue;
  BOOL _trapOpen;
  
  double _currentStreamSeekTime;
  CGFloat _currentPlayerVolume;
  
  StreamingContentType _streamingContentType;
  
  AudioFadedCallback fadeCallback;
  
}

@property (nonatomic,strong) AudioStreamer *audioStreamer;
@property (nonatomic,strong) AVPlayer *audioPlayer;
@property (nonatomic,strong) NSTimer *audioParsingTimer;
@property (nonatomic,strong) NSString *lastPlayedStreamURLString;
@property (nonatomic,strong) NSMutableArray *apiStreamerPool;
@property (nonatomic,strong) NSMutableDictionary *apiStreamerLocks;
@property (nonatomic,strong) NSMutableArray *hungryObjects;

@property (nonatomic,weak) id<AudioManagerDelegate> delegate;
@property (nonatomic,strong) id timeObserver;

@property BOOL streamPlaying;
@property BOOL localPlaying;
@property BOOL paused;
@property BOOL seeking;
@property BOOL rebootStream;
@property BOOL fadeRequested;
@property BOOL playingQueue;
@property BOOL trapOpen;
@property BOOL muted;
@property BOOL playerSilencedAutomatically;
@property BOOL timeToSave;
@property BOOL bootingLiveStream;
@property BOOL disarmAfterResume;
@property BOOL isPlayingLiveStream;

@property NSUInteger ticksSinceSave;

@property CGFloat savedVolume;

@property BOOL audioWasInterrupted;

@property double currentStreamSeekTime;
@property CGFloat currentPlayerVolume;
@property StreamingContentType streamingContentType;

+ (AudioManager*)shared;
- (void)prime;

// APIStreamer
- (AVAudioPlayer*)requestAudioPlayer:(NSString*)urlString;
- (void)unlockAudioPlayer:(AVAudioPlayer*)avp;

// AudioStreamer
- (void)buildStreamer:(NSString*)urlForStream;
- (void)buildApiStreamer:(NSString*)urlForStream;
- (void)takedownStreamer;
- (void)armAudioParsingTimer;
- (void)disarmAudioParsingTimer;
- (void)startStream:(NSString*)streamURL;
- (void)stopStream;
- (void)pauseStream;
- (void)unpauseStream;
- (void)resumeAudio;
- (void)seekStream:(double)seekValue;
- (void)adjustVolume:(CGFloat)volumeLevel;
- (void)pushSilence;
- (void)popSilence;
- (void)fadeAudio:(AudioFadedCallback)callback hard:(BOOL)hard;
- (BOOL)isPlayingAnyAudio;
- (BOOL)isPlayingOnDemand;
- (void)failAudioWithError:(NSString*)error;
- (void)mainThreadUpdate;
- (void)handleInterruptSegmentAudio:(NSDictionary*)audioMeta;
- (void)broadcastPlayMessage;
- (void)watchAudioThroughput:(id)watcher;
- (void)removeWatcher:(id)watcher;

@end
