//
//  SCPRTopicSchema.h
//  KPCC
//
//  Created by Ben Hochberg on 4/18/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCPRTopicSchema : NSObject {
  NSMutableDictionary *_topicHeadings;
  NSMutableArray *_sortedTopics;
}

@property (nonatomic,strong) NSMutableDictionary *topicHeadings;
@property (nonatomic,strong) NSMutableArray *sortedTopics;

@end
