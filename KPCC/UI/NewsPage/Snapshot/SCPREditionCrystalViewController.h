//
//  SCPREditionCrystalViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRSnapshotCell.h"
#import "SCPRWebNewsContentViewController.h"
#import "SCPRHBTView.h"
#import "SCPRGrayLineView.h"
#import "SCPRWebNewsContentViewController.h"
#import "SCPRFlapViewController.h"

@interface SCPREditionCrystalViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIWebViewDelegate,WebContentContainer,Turnable>

@property (nonatomic,strong) NSMutableArray *snapshotContent;

@property (nonatomic,strong) IBOutlet UILabel *snapshotHeadingLabel;
@property (nonatomic,strong) IBOutlet UIView *headerBar;
@property (nonatomic,strong) IBOutlet UIImageView *splashBannerImageView;
@property (nonatomic,strong) IBOutlet UIView *tableContainer;
@property (nonatomic,strong) IBOutlet UITableView *summaryTableView;
@property (nonatomic,strong) IBOutlet UIView *detailContainer;
@property (nonatomic,strong) IBOutlet UIView *dateContainer;
@property (nonatomic,strong) IBOutlet UILabel *dateLabel;
@property (nonatomic,strong) IBOutlet UILabel *dateNotesLabel;
@property (nonatomic,strong) IBOutlet UIImageView *featuredSourceImage;
@property (nonatomic,strong) IBOutlet UIWebView *webView;
@property (nonatomic,strong) IBOutlet UIImageView *backstageImage;
@property (nonatomic,strong) IBOutlet UIView *orangeFooterView;
@property (nonatomic,strong) IBOutlet UIView *cardView;
@property (nonatomic,strong) IBOutlet UIView *infoHeaderView;

@property (nonatomic,weak) UIImageView *currentImageView;
@property (nonatomic,strong) NSMutableArray *splashImages;
@property (nonatomic,strong) NSMutableDictionary *cellHash;

@property (nonatomic,strong) NSDate *snapshotDate;
@property NSUInteger edition;

@property (nonatomic,strong) UIImage *blurryImage;
@property (nonatomic,strong) SCPRSnapshotCell *dummyCell;

@property (nonatomic,strong) IBOutlet SCPRWebNewsContentViewController *webVideo;
@property (nonatomic,strong) IBOutlet UILabel *videoCaptionLabel;
@property (nonatomic,strong) IBOutlet SCPRHBTView *featureContent;

@property (nonatomic,strong) IBOutlet UIView *moreStoriesFooter;
@property (nonatomic,strong) IBOutlet UILabel *moreStoriesLabel;
@property (nonatomic,strong) IBOutlet UILabel *storyMetricsLabel;
@property (nonatomic,strong) IBOutlet UIButton *launchEditionButton;

@property (nonatomic,weak) id parentMineral;
@property (nonatomic,strong) UINavigationController *designatedNav;

@property (nonatomic,strong) IBOutlet SCPRGrayLineView *gl1;
@property (nonatomic,strong) IBOutlet UIView *gl2;
@property (nonatomic,strong) IBOutlet SCPRWebNewsContentViewController *webContentLoader;
@property (nonatomic,strong) IBOutlet UIView *tableSeatView;

@property (nonatomic,strong) NSMutableDictionary *masterContent;
@property NSInteger editionIndex;
@property (nonatomic,strong) UIScrollView *observableScroller;
@property (nonatomic,strong) IBOutlet UIView *shadowView;
@property CGRect originalFrame;
@property (nonatomic,strong) SCPRFlapViewController *leftFlap;
@property (nonatomic,strong) SCPRFlapViewController *rightFlap;

@property (nonatomic,strong) id pushedContent;
@property NSInteger pushedAtomIndex;

- (UIImage*)imageForSourceString:(NSString*)source;
- (void)attachEdition:(NSUInteger)edition;
- (void)attachDate;
- (void)primeStyle;
- (void)silencePage:(NSInteger)index;
- (void)awakenPage;
- (void)popLoad;
- (void)buildCells;
- (void)prime;
- (void)pushToMolecule:(NSInteger)atomIndex;
- (IBAction)buttonTapped:(id)sender;

@end
