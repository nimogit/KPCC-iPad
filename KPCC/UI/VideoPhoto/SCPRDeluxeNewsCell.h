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
@property (nonatomic,strong) IBOutlet UIView *containerSlateView;

@property (nonatomic,strong) NSArray *posts;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@property (nonatomic,strong) IBOutlet NSLayoutConstraint *topSpacing;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *leftSpacing;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *widthConstraint;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *betweenConstraint;


@property BOOL squished;
@property BOOL primed;
@property BOOL landscape;

- (void)prime:(id)parent;
- (void)squish;
- (void)swapFacades:(UIView*)newFacade container:(SCPRDeluxeNewsFacadeViewController*)container values:(NSDictionary*)values;

@end
