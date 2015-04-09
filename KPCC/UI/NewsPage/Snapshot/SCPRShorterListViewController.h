//
//  SCPRShorterListViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/7/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"
#import "SCPRAppDelegate.h"

@interface SCPRShorterListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,Rotatable>

@property (nonatomic, strong) IBOutlet UIImageView *splashImageView;
@property (nonatomic, strong) IBOutlet SCPRGrayLineView *dividerLineView;
@property (nonatomic, strong) IBOutlet UIView *headlineSeatView;
@property (nonatomic, strong) IBOutlet UILabel *shortListLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateTimeLabel;
@property (nonatomic, strong) IBOutlet UITableView *contentsTable;
@property (nonatomic, strong) IBOutlet UIScrollView *contentScroller;
@property (nonatomic, strong) IBOutlet UIView *scrollingContentView;
@property (nonatomic, strong) IBOutlet UIView *curtainView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *headlineSeatConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *tableHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *inlineContentPushConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *scrollingContentHeightConstraint;

@property (nonatomic, strong) NSMutableArray *stories;
@property (nonatomic, weak) id parentMolecule;
@property BOOL fromNews;

- (void)setupWithEdition:(NSDictionary*)edition;
- (void)pushToStoryAtIndex:(NSInteger)index;
- (void)setupScrollingDimensionsWithStories:(NSMutableArray*)stories;
- (NSString*)formattedTimestampForEdition:(NSDictionary*)edition;

@end
