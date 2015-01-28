//
//  SCPRQueueViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRFlatShadedButton.h"
#import "SCPRGrayLineView.h"
#import "SCPRSpinnerViewController.h"
#import "SCPRSleepTimerTableViewController.h"

@class SCPRQueueCellViewController;

@interface SCPRQueueViewController : UIViewController<QueueDelegate,UITableViewDataSource,UITableViewDelegate,ContentProcessor>

@property (nonatomic,strong) IBOutlet UIScrollView *queueScroller;
@property (nonatomic,strong) IBOutlet UIView *maskView;
@property (nonatomic,strong) NSMutableArray *queueContent;
@property (nonatomic,strong) NSMutableArray *queueVisualContent;
@property (nonatomic,strong) IBOutlet UIImageView *emptyQueueBox;
@property (nonatomic,strong) IBOutlet UILabel *currentPlayingDetails;
@property (nonatomic,strong) IBOutlet UILabel *queueStatusLabel;
@property (nonatomic,strong) IBOutlet UILabel *authorLabel;
@property (nonatomic,strong) IBOutlet UILabel *teaserLabel;
@property (nonatomic,strong) IBOutlet UILabel *upcomingLabel;
@property (nonatomic,strong) IBOutlet UITableView *queueTable;
@property (nonatomic,strong) IBOutlet UIButton *editButton;
@property (nonatomic,strong) IBOutlet UIButton *cancelButton;
@property (nonatomic,strong) NSMutableArray *theoreticalQueue;
@property (nonatomic,strong) IBOutlet UILabel *storyCountLabel;
@property (nonatomic,strong) IBOutlet UIView *containerHeadView;
@property (nonatomic,strong) IBOutlet UILabel *queueTitleLabel;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *backToTopButton;
@property (nonatomic,strong) IBOutlet UILabel *minifiedQueueCountLabel;

@property (nonatomic,strong) IBOutlet SCPRGrayLineView *leftVerticalDivider;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *rightVerticalDivider;
@property (nonatomic,strong) IBOutlet UIButton *dismissButton;
@property (nonatomic,strong) IBOutlet UIButton *removeAllButton;
@property (nonatomic,strong) IBOutlet UIView *currentlyPlayingSeat;
@property (nonatomic,strong) IBOutlet UILabel *myQueueLabel;
@property (nonatomic,strong) IBOutlet UILabel *nowPlayingLabel;
@property (nonatomic,strong) IBOutlet UIView *topSeatView;
@property (nonatomic,strong) IBOutlet UIView *controlSeatView;
@property (nonatomic,strong) IBOutlet UISwipeGestureRecognizer *dismissSwiper;
@property (nonatomic,strong) IBOutlet UIButton *actionButton;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *playPauseSpinner;
@property (nonatomic,strong) IBOutlet UILabel *switchToLiveLabel;
@property (nonatomic,strong) IBOutlet UIButton *switchToLiveButton;
@property (nonatomic,strong) IBOutlet UIImageView *switchToLiveImage;
@property (nonatomic,strong) IBOutlet UIButton *sleepTimerButton;
@property (nonatomic,strong) IBOutlet UIImageView *sleepTimerImage;
@property (nonatomic,strong) IBOutlet UILabel *sleepTimerLabel;
@property (nonatomic,strong) IBOutlet UIButton *sleepTimerCancelButton;
@property (nonatomic,strong) IBOutlet UILabel *sleepTimerCancelLabel;
@property (nonatomic,strong) IBOutlet UIView *sleepTimerActiveView;
@property (nonatomic,strong) IBOutlet UIView *sleepTimerInactiveView;
@property (nonatomic,strong) IBOutlet UILabel *sleepTimerClockLabel;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *sleepTimerVerticalDivider;
@property (nonatomic,strong) IBOutlet SCPRSleepTimerTableViewController *sleepTimerTableViewController;


@property (nonatomic,weak) id parent;
@property (nonatomic,weak) id parentRoot;
@property (nonatomic,weak) id cellToRemoveFromQueue;
@property (nonatomic,weak) id cellToQueueUp;
@property (nonatomic,weak) id cellNewPlaying;

@property (nonatomic,strong) SCPRQueueCellViewController *dummyQCV;
@property (nonatomic,strong) IBOutlet UIView *queueFormatControlView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *queueSlidableGrayLineView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *queueBottomGrayLineView;
@property (nonatomic,strong) IBOutlet UIImageView *triangleSlider;
@property (nonatomic,strong) IBOutlet UIButton *myQueueButton;
@property (nonatomic,strong) IBOutlet UIButton *liveRewindButton;
@property (nonatomic,strong) IBOutlet UILabel *liveRewindLabel;
@property (nonatomic,strong) IBOutlet UIScrollView *formatScroller;
@property (nonatomic,strong) IBOutlet UIView *emptyMsgSeat;
@property (nonatomic,strong) IBOutlet UIButton *addFiveButton;
@property (nonatomic,strong) NSMutableDictionary *confirmedDeletions;
@property (nonatomic,strong) IBOutlet UIImageView *mouthImage;
@property (nonatomic,strong) SCPRSpinnerViewController *spinner;
@property (nonatomic,strong) UIActivityIndicatorView *nativeSpinner;

@property BOOL suspend;
@property BOOL editing;
@property (nonatomic) BOOL dirty;
@property BOOL topShowing;
@property BOOL playingItemChanging;
@property BOOL seeking;
@property BOOL openTrapForStop;
@property BOOL openTrapForResume;
@property BOOL lockFromGhosting;
@property BOOL waitingForFive;
@property BOOL silentSquish;

@property NSInteger received;

@property CGRect topButtonOriginalFrame;

@property (nonatomic,strong) UIPopoverController *sleepTimerModal;
@property (nonatomic,strong) NSTimer *sleepTimerLabelUpdateTimer;

- (void)buildQueue;
- (void)prime;
- (id)primeCell:(SCPRQueueCellViewController*)cell withIndex:(NSUInteger)index;

- (void)primeButtonsForState;
- (void)primeQueueForState;

- (IBAction)editQueue:(id)sender;
- (IBAction)cancelEdits:(id)sender;
- (IBAction)backToTopTapped:(id)sender;
- (IBAction)emptyQueue:(id)sender;
- (IBAction)formatSelected:(id)sender;
- (IBAction)deleteConfirmed:(id)sender;
- (IBAction)deleteCommitted:(id)sender;
- (IBAction)userWantsFive:(id)sender;
- (IBAction)dismissTapped:(id)sender;
- (IBAction)playOrPauseTapped:(id)sender;
- (IBAction)switchToLiveTapped:(id)sender;
- (IBAction)sleepTimerTapped:(id)sender;
- (IBAction)sleepTimerCancelTapped:(id)sender;

- (void)closeSleepTimerModal;
- (void)updateSleepTimeLeft;

- (void)dropAllItemsFromQueue;
- (void)handleEditMode;
- (void)stampQueueOrderNumbers;

- (void)selectMyQueue;
- (void)selectLiveRewind;

- (void)bootUpQueue:(id)cell;
- (void)bootUpLiveStream;

- (void)exposeTopButton;
- (void)hideTopButton;




@end
