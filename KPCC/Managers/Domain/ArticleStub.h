//
//  ArticleStub.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ArticleStub : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * links;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * created_at;

@end
