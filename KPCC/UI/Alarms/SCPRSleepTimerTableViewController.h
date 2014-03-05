//
//  SCPRSleepTimerTableViewController.h
//  KPCC
//
//  Created by John Meeker on 3/3/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@interface SCPRSleepTimerTableViewController : UITableViewController <UITableViewDataSource>

@property (nonatomic,strong) NSMutableArray *sleepTimerData;
@property (nonatomic, weak)id queueViewControllerDelegate;

@end
