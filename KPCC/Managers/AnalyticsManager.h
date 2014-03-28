//
//  AnalyticsManager.h
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "global.h"
#include <mach/mach_time.h>

typedef enum {
  StreamStateHealthy = 0,
  StreamStateLostConnectivity = 1,
  StreamStateServerFail = 2,
  StreamStateUnknown = 3
} StreamState;


@interface AnalyticsManager : NSObject {
  BOOL _audioStreamInFailedState;
  NSInteger _droppedPackets;
  StreamState _interruptionCause;
}

@property BOOL audioStreamInFailedState;
@property (nonatomic,strong) NSDate *streamDropped;
@property (nonatomic,strong) NSDate *streamRestored;
@property NSInteger droppedPackets;
@property StreamState interruptionCause;
@property NSInteger screenContent;
@property NSInteger savedScreenContent;
@property BOOL timedSessionOpen;
@property NSTimeInterval sessionBegan;
@property CGFloat start;
@property CGFloat finish;
@property BOOL timing;

@property (nonatomic,strong) NSNumber *numberOfSwipesPerAd;
@property (nonatomic,strong) NSNumber *numberOfAdsPerSession;
@property (nonatomic,strong) NSString *adVendorID;
@property (nonatomic,strong) NSString *adUnitID;
@property (nonatomic,strong) NSString *adGtpID;
@property (nonatomic,strong) NSString *urlHint;

+ (AnalyticsManager*)shared;
- (void)primeAnalytics;
- (void)failStream:(StreamState)cause comments:(NSString*)comments;
- (void)unfailStream;
- (NSString*)stringForInterruptionCause:(StreamState)cause;
- (NSDictionary*)mergeParametersWithUserInfo:(NSDictionary*)extraParams callingFunction:(NSString*)callingFunction;

// Error logging
- (void)analyzeStreamError:(NSString*)comments;
- (void)networkDisappeared;
- (void)failureFetchingImage:(NSString*)link;
- (void)failureFetchingContent:(NSString*)link;
- (void)logEvent:(NSString*)event withParameters:(NSDictionary*)parameters;
- (void)openTimedSessionForContentType:(NSInteger)contentType;
- (void)terminateTimedSessionForContentType:(NSInteger)contentType;
- (void)app404;

- (NSDictionary*)paramsForArticle:(NSDictionary*)article;
- (void)tS;
- (void)tF:(NSString*)functionName;
- (CGFloat) getUptimeInMilliseconds;

- (void)retrieveAdSettings;

@end
