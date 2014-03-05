//
//  SCPREditionShortListViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 10/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayLineView.h"

@interface SCPREditionShortListViewController : UIViewController

@property (nonatomic,strong) IBOutlet UILabel *shortListTitleLabel;
@property (nonatomic,strong) IBOutlet UIView *numberOfStoriesSeat;
@property (nonatomic,strong) IBOutlet UILabel *numberOfStoriesLabel;
@property (nonatomic,strong) IBOutlet UILabel *leadStoryHeadlineLabel;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *dividerLine;
@property (nonatomic,strong) IBOutlet UIView *leadStorySeatView;
@property (nonatomic,strong) IBOutlet UILabel *plusLabel;
@property (nonatomic,strong) IBOutlet UILabel *moreStoriesListLabel;
@property (nonatomic,strong) IBOutlet UIView *readMoreSeat;
@property (nonatomic,strong) IBOutlet UIButton *readMoreButton;
@property (nonatomic,strong) IBOutlet UIView *cruxView;
@property (nonatomic,strong) IBOutlet UIImageView *leadAssetImage;
@property (nonatomic,strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic,strong) IBOutlet UIButton *drillDownButton;
@property (nonatomic,strong) IBOutlet UIView *additionalSeat;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic,weak) id pushedContent;
@property (nonatomic,weak) id parentMineral;
@property BOOL fromNews;

@property NSInteger pushedAtomIndex;

@property (nonatomic,strong) NSDictionary *edition;

- (void)setupWithEdition:(NSDictionary*)edition;
- (void)prime;
- (NSString*)buildList:(NSDictionary*)edition;

- (void)shrink;
- (void)pushTitleUp;
- (void)pushToMolecule:(NSInteger)atomIndex;
- (void)proxyPush;
- (void)shrinkStoriesBox;

@end
