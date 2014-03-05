//
//  QueueManager.h
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioManager.h"
#import "Segment.h"

@class Collection;

@protocol QueueDelegate <NSObject>

@required

- (void)queueAddedTo;
- (void)queueRemovedFrom;
- (void)pop:(id)segment;
- (void)findAndPlayArticle:(Segment*)article;
- (NSMutableArray*)representation;

@end

@interface QueueManager : NSObject

@property (nonatomic,weak) id<QueueDelegate> delegate;
@property (nonatomic,strong) Collection *queue;
@property (nonatomic,strong) NSMutableDictionary *queueAssets;
@property (nonatomic,strong) NSDictionary *stories;
@property BOOL queuePlaying;
@property BOOL editingQueue;

@property (nonatomic,strong) Segment *currentlyPlayingSegment;

@property NSUInteger operatingOnIndex;
@property CGFloat interruptionTime;

+ (QueueManager*)shared;

- (void)addToQueue:(NSDictionary*)article asset:(NSString*)asset;
- (void)addToQueue:(NSDictionary *)article asset:(NSString *)asset playImmediately:(BOOL)playImmediately;
- (void)silentlyAddToQueue:(NSArray*)articles;

- (void)pushToQueueLiteral:(id)segment asset:(UIImage*)asset;
- (void)removeFromQueue:(NSDictionary*)article;
- (void)removeFromQueueLiteral:(id)segment;
- (void)silentlyRemoveFromQueue:(id)segment;
- (void)start:(id)segment;
- (void)liveStream;
- (void)writeSegmentProgress:(double)progress commit:(BOOL)commit;
- (void)handleInterruption:(CGFloat)currentTime;
- (BOOL)articleIsInQueue:(NSDictionary*)article;
- (BOOL)articleIsPlayingNow:(NSDictionary*)article;
- (BOOL)queueIsEmpty;
- (void)segmentListenedTo;
- (void)pluckFiveAndAddToQueue;
- (void)playSpecificArticle:(id)article;
- (void)pop;

@end
