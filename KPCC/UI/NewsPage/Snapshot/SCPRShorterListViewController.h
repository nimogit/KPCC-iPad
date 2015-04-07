//
//  SCPRShorterListViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/7/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPRShorterListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *splashImageView;
@property (nonatomic, strong) IBOutlet SCPRGrayLineView *dividerLineView;
@property (nonatomic, strong) IBOutlet UIView *headlineSeatView;
@property (nonatomic, strong) IBOutlet UILabel *shortListLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateTimeLabel;
@property (nonatomic, strong) IBOutlet UITableView *contentsTable;
@property (nonatomic, strong) NSMutableArray *stories;
@property (nonatomic, weak) id parentMolecule;
@property BOOL fromNews;

- (void)setupWithEdition:(NSDictionary*)edition;
- (void)pushToStoryAtIndex:(NSInteger)index;
- (NSString*)formattedTimestampForEdition:(NSDictionary*)edition;

@end
