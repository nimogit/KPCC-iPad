//
//  Keyword.h
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/****************************************************/
// -- Developer Note --
// This domain object isn't really used for anything, but at one point before we'd officially decided on the implementation of the Queue and
// how the user can group segments and programs I thought it might be useful to be able to associate segments with keywords. The idea here
// was that users could create a "channel" based on keywords like Politics, Science, etc. and that way Segments with those tags associated with
// them would filter into their channel. This concept never got off the ground, but the basic hooks are here. Worth exploring at some point perhaps.
//
@class Collection, Segment;

@interface Keyword : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSNumber * keywordType;
@property (nonatomic, retain) NSSet *segments;
@property (nonatomic, retain) NSSet *collections;
@end

@interface Keyword (CoreDataGeneratedAccessors)

- (void)addSegmentsObject:(Segment *)value;
- (void)removeSegmentsObject:(Segment *)value;
- (void)addSegments:(NSSet *)values;
- (void)removeSegments:(NSSet *)values;

- (void)addCollectionsObject:(Collection *)value;
- (void)removeCollectionsObject:(Collection *)value;
- (void)addCollections:(NSSet *)values;
- (void)removeCollections:(NSSet *)values;

@end
