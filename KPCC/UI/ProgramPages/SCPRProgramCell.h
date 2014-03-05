//
//  SCPRProgramCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/26/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRFloatingOptionViewController.h"

@interface SCPRProgramCell : UITableViewCell<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) IBOutlet UIButton *actionButton;
@property (nonatomic,strong) IBOutlet UILabel *episodeTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *episodeLengthLabel;
@property (nonatomic,strong) IBOutlet UILabel *numberOfSegmentsLabel;
@property (nonatomic,strong) IBOutlet UIButton *showSegmentsButton;
@property (nonatomic,strong) NSDictionary *programEpisode;
@property CGRect originalHeadlineFrame;
@property CGRect originalSegmentsLabelFrame;

@property (nonatomic,strong) IBOutlet UITableView *segmentsTable;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic,strong) NSIndexPath *modifiedRow;
@property (nonatomic,strong) NSArray *segments;
@property (nonatomic,weak) id parentController;

- (void)mainPlayRequested:(id)sender;
- (IBAction)playRequested:(id)sender;
- (void)refresh;

@end
