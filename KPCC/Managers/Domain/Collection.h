//
//  Collection.h
//  KPCC
//
//  Created by Ben on 4/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Keyword, Segment;

@interface Collection : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * collectionType;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSSet *segments;
@property (nonatomic, retain) NSSet *keywords;
@end

@interface Collection (CoreDataGeneratedAccessors)

- (void)addSegmentsObject:(Segment *)value;
- (void)removeSegmentsObject:(Segment *)value;
- (void)addSegments:(NSSet *)values;
- (void)removeSegments:(NSSet *)values;

- (void)addKeywordsObject:(Keyword *)value;
- (void)removeKeywordsObject:(Keyword *)value;
- (void)addKeywords:(NSSet *)values;
- (void)removeKeywords:(NSSet *)values;

@end
