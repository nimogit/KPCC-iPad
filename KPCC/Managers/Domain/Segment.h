//
//  Segment.h
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Collection, Keyword;

@interface Segment : NSManagedObject

@property (nonatomic, retain) NSDate * airdate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * seekposition;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSSet *collections;
@property (nonatomic, retain) NSSet *keywords;
@property (nonatomic, retain) NSDate * addedToQueueDate;
@property (nonatomic, retain) NSString * originalArticle;
@property (nonatomic, retain) NSString * thumbnail;
@property (nonatomic, retain) NSNumber * queuePosition;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSString * program;
@end

@interface Segment (CoreDataGeneratedAccessors)

- (void)addCollectionsObject:(Collection *)value;
- (void)removeCollectionsObject:(Collection *)value;
- (void)addCollections:(NSSet *)values;
- (void)removeCollections:(NSSet *)values;

- (void)addKeywordsObject:(Keyword *)value;
- (void)removeKeywordsObject:(Keyword *)value;
- (void)addKeywords:(NSSet *)values;
- (void)removeKeywords:(NSSet *)values;

- (BOOL)isCurrentlyPlaying;

@end
