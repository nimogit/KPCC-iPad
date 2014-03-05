//
//  SCPRShareDrawerViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRExternalWebContentViewController.h"

#ifdef IPAD_VERSION
@interface SCPRShareDrawerViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,ExternalWebContentDelegate,UIPopoverControllerDelegate>
#else
@interface SCPRShareDrawerViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,ExternalWebContentDelegate>
#endif

@property (nonatomic,strong) IBOutlet UITableView *shareMethodTable;
@property (nonatomic,strong) NSMutableArray *shareCells;
@property (nonatomic,strong) UISwipeGestureRecognizer *dismissSwiper;
@property (nonatomic,weak) UIViewController *singleArticleDelegate;

- (void)buildCells;

@end
