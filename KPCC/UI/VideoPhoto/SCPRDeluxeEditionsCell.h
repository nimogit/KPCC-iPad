//
//  SCPRDeluxeEditionsCell.h
//  KPCC
//
//  Created by Ben on 8/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPREditionShortListViewController.h"

@interface SCPRDeluxeEditionsCell : UITableViewCell

@property (nonatomic,strong) IBOutlet SCPREditionShortListViewController *shortListController;
@property (nonatomic,weak) id parentController;
@property (nonatomic,strong) NSDictionary *mainEdition;

@property BOOL primed;
@property BOOL squished;

- (void)squish;
- (void)prime:(id)parent;

@end
