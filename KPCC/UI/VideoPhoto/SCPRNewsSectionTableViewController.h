//
//  SCPRNewsSectionTableViewController.h
//  KPCC
//
//  Created by John Meeker on 4/28/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SCPRNewsSectionDelegate <NSObject>
@optional
- (void)sectionSelected;
@end

@interface SCPRNewsSectionTableViewController : UITableViewController

@property (nonatomic,strong) NSMutableArray *sections;
@end
