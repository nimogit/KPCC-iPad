//
//  SCPRNewsSectionTableViewController.h
//  KPCC
//
//  Created by John Meeker on 4/28/14.
//  Copyright (c) 2014 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "FXBlurView.h"

@protocol SCPRNewsSectionDelegate <NSObject>
@optional
- (void)sectionSelected:(NSString *)sectionSlug;
@end

@interface SCPRNewsSectionTableViewController : UITableViewController<Rotatable>

@property (nonatomic,weak) id<SCPRNewsSectionDelegate> sectionsDelegate;
@property (nonatomic,strong) NSMutableArray *sections;
@property (nonatomic,strong) NSString *currentSectionSlug;

@end
