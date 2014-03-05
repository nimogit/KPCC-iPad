//
//  SCPRListableObject.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCPRModalListPickerViewController.h"

@interface SCPRListableObject : NSObject<Listable>

@property (nonatomic,strong) NSString *stringRepresentation;
@property (nonatomic,strong) id item;

@end
