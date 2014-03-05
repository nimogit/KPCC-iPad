//
//  SCPRDeluxeNewsCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRDeluxeNewsFacadeViewController.h"

@interface SCPRDeluxeNewsCell : UITableViewCell

@property (nonatomic,strong) IBOutlet SCPRDeluxeNewsFacadeViewController *facade0;
@property (nonatomic,strong) IBOutlet SCPRDeluxeNewsFacadeViewController *facade1;
@property (nonatomic,strong) NSArray *posts;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@property BOOL squished;
@property BOOL primed;
@property BOOL landscape;

- (void)prime:(id)parent;
- (void)squish;

@end
