//
//  NetworkManager.h
//  KPCC
//
//  Created by Ben on 4/3/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCPRTopicSchema.h"
#import "Reachability.h"

#define kImageCacheMaxSize 8192
#define kImageCacheMaxSizeDisk 16384
#define kMinimumArticleQuantity 15
#ifndef DEBUG
#define kServerBase @"http://www.scpr.org/api/v2"
#else
#define kServerBase @"http://205.144.162.154/api/v2"
#endif
#define kAudioVisionServerBase @"http://audiovision.scpr.org/api/v1"
#define kEditionsTotal 12
#define kFailoverThreshold 4


@protocol ContentProcessor <NSObject>
@optional
- (void)handleAdditionalContent:(NSArray*)content forTopic:(NSString*)topic;
- (NSInteger)numberOfStoriesPerPage;
- (NSMutableArray*)mediaContentForTopic:(NSString*)topic;
- (NSMutableArray*)additionalContentForTopic:(NSString*)topic;
- (NSMutableArray*)mediaContent;
- (void)handleReducedArticle:(NSDictionary*)reducedArticle;
- (void)handleCompositeNews:(NSDictionary*)content;
- (void)handleVideoPhoto:(NSDictionary*)content;
- (void)handleEditionals:(NSArray*)editionals;
- (void)handleEvents:(NSDictionary*)content;
- (void)contentFinishedDisplaying;
- (void)handleProcessedContent:(NSArray*)content flags:(NSDictionary*)flags;
@required
@end

typedef enum {
  NetworkHealthUnknown = 0,
  NetworkHealthServerOK = 1,
  NetworkHealthNetworkOK = 2,
  NetworkHealthServerDown = 3,
  NetworkHealthNetworkDown = 4,
  NetworkHealthAllOK = 5
} NetworkHealth;

@interface NetworkManager : NSObject {
  Reachability *_networkHealthReachability;
}

@property (nonatomic,strong) Reachability *networkHealthReachability;
@property (nonatomic,strong) SCPRTopicSchema *globalSchema;
@property (nonatomic,strong) NSDate *lastContentRefresh;
@property (nonatomic,strong) NSMutableDictionary *videoPhotoObjects;

@property (atomic) BOOL compositeEditionsFetchFinished;
@property (atomic) BOOL compositeMainNewsFetchFinished;
@property BOOL refreshOnWake;
@property BOOL compositeFetched;
@property BOOL completionListenerEnabled;

@property (nonatomic,strong) NSOperationQueue *programsFetchQueue;

@property NSInteger failoverCount;

- (BOOL)isReadyForRefresh;
+ (NetworkManager*)shared;
- (SCPRTopicSchema*)fetchTopicSchema;
- (NetworkHealth)checkNetworkHealth:(NSString*)server;
- (NSString*)networkInformation;
- (BOOL)isWifi;

// Content Fetching
- (void)fetchAllContent:(id<ContentProcessor>)display;
- (void)fetchContentWithPath:(NSString*)newsPath display:(id<ContentProcessor>)display;
- (void)fetchContentForProgramPage:(NSString*)newsPath display:(id<ContentProcessor>)display;
- (void)fetchTrendingArticles:(id<ContentProcessor>)display;
- (void)fetchContentForEventsPage:(NSString*)newsPath display:(id<ContentProcessor>)display;
- (void)fetchContentForVideoPhotoPage:(id<ContentProcessor>)display;
- (void)fetchContentForSnapshotPage:(id<ContentProcessor>)display;
- (void)fetchContentForSnapshotPage:(id<ContentProcessor>)display flags:(NSDictionary*)flags;
- (void)fetchContentForEditionals:(id<ContentProcessor>)display;
- (void)fetchContentForSingleArticle:(NSString*)articleURL display:(id<ContentProcessor>)display;
- (void)fetchContentForTopic:(NSString*)topic display:(id<ContentProcessor>)display flags:(NSDictionary*)flags;
- (void)fetchContentForUserProfile:(id<ContentProcessor>)display;
- (void)fetchContentForProgramAZPage:(id<ContentProcessor>)display;
- (void)fetchContentForProgramAZPageSilently;
- (void)fetchContentForMasterProgramsList:(id<ContentProcessor>)display;
- (void)fetchContentForScheduleThisWeek:(id<ContentProcessor>)display;
- (void)fetchProgramInformationFor:(NSDate*)thisTime display:(id<ContentProcessor>)display;
- (void)processContentData:(NSDictionary*)content;
- (void)processCompositeData:(NSDictionary*)compositeContent;
- (void)processVideoPhotoData:(NSDictionary*)videoPhotoContent;
- (void)processEventsData:(NSDictionary*)content;
- (void)requestFromKPCCWithEndpoint:(NSString*)endpoint andDisplay:(id<ContentProcessor>)display;
- (void)requestFromKPCCWithEndpoint:(NSString *)endpoint andDisplay:(id<ContentProcessor>)display flags:(NSDictionary*)flags;
- (void)fetchEditionsInBackground;

- (NSString*)readabilityAPIKey;
- (NSInteger)satisfactoryLoadBalanceBetween:(NSMutableArray*)thisArray andThatArray:(NSMutableArray*)thatArray;
- (void)reduceArticle:(NSString*)url processor:(id<ContentProcessor>)processor;
- (void)remoteReductionForArticle:(NSString*)url processor:(id<ContentProcessor>)processor;
- (NSString*)localReduction:(NSString*)fullContent processor:(id<ContentProcessor>)processor;
- (NSString*)stringForSchemaComponent:(NSString*)code;

@end
