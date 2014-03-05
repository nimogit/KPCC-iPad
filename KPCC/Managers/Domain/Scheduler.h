//
//  Scheduler.h
//  KPCC
//
//  Created by Hochberg, Ben on 10/18/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Scheduler : NSManagedObject

@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSDate * lastsync;

@end
