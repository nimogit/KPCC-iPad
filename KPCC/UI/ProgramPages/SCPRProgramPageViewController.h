//
//  SCPRProgramPageViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRViewController.h"
#import "SCPRSpinnerViewController.h"
#import "global.h"
#import "SCPRProgramCell.h"

@interface SCPRProgramPageViewController : UIViewController<ContentProcessor,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,Backable,Rotatable>

@property (nonatomic,strong) IBOutlet UIImageView *image1;
@property (nonatomic,strong) IBOutlet UIImageView *image2;
@property (nonatomic,strong) IBOutlet UIImageView *image3;
@property (nonatomic,strong) IBOutlet UIImageView *image4;

@property (nonatomic,strong) IBOutlet UILabel *programTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *programSubtitleLabel;
@property (nonatomic,strong) IBOutlet UIImageView *splashImage;
@property (nonatomic,strong) IBOutlet UITableView *episodeTable;
@property (nonatomic,strong) IBOutlet UIImageView *gradientImage;
@property (nonatomic,strong) IBOutlet UIImageView *circleGradient;
@property (nonatomic,strong) IBOutlet UIView *tableSeat;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *nativeSpinner;

@property (nonatomic,strong) IBOutlet UIView *detailSeatView;
@property (nonatomic,strong) IBOutlet UIView *showTitleView;
@property (nonatomic,strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic,strong) IBOutlet UIButton *airtimeButton;
@property (nonatomic,strong) IBOutlet UIButton *websiteButton;
@property (nonatomic,strong) IBOutlet UIButton *twitterButton;
@property (nonatomic,strong) IBOutlet UILabel *broadcastsAtLabel;
@property (nonatomic,strong) IBOutlet UILabel *websiteLabel;
@property (nonatomic,strong) IBOutlet UILabel *twitterLabel;

@property (nonatomic,strong) NSMutableDictionary *segmentTableHash;
@property (nonatomic,strong) NSDictionary *programObject;
@property (nonatomic,strong) NSArray *showData;
@property (nonatomic,strong) NSMutableDictionary *cellWithSegmentsHash;

@property (nonatomic,strong) UISwipeGestureRecognizer *swipeDownToReveal;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeUpToObscure;

@property (nonatomic,strong) UIView *topHeader;

@property BOOL revealing;
@property (atomic) BOOL animationLock;
@property (atomic) BOOL populateOnAppearance;
@property (atomic) BOOL accessedFromAZ;
@property BOOL merged;
@property BOOL loaded;

@property (nonatomic,strong) IBOutlet UIButton *toggleTable;
@property (nonatomic,strong) NSNumber *expandedCellTag;

@property (nonatomic,strong) IBOutlet UIView *fillerFooterView;

@property (nonatomic,strong) IBOutlet SCPRSpinnerViewController *spinner;

@property (nonatomic,weak) id parentAZPage;
@property (nonatomic,weak) UIScrollView *mainScroller;
@property (nonatomic,strong) IBOutlet UIView *cloakView;

@property (nonatomic,strong) SCPRProgramCell *dummyCell;



- (void)fetchShowInformation;
- (IBAction)buttonTapped:(id)sender;
- (IBAction)toggleSegments:(id)sender;
- (IBAction)playRequested:(id)sender;
- (void)mergeWithShow;
- (void)synthesizeShowData:(NSArray*)showData;
- (NSInteger)calculateTagForIndexPath:(NSIndexPath*)indexPath;
- (NSString*)imageNameForProgram;

@end
