//
//  SCPRViewController.h
//  KPCC
//
//  Created by Ben on 4/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//
//  Hello

#import <UIKit/UIKit.h>
#import "SCPRPlayerWidgetViewController.h"
#import "SCPRTitlebarViewController.h"
#import "global.h"
#import "SCPRShareDrawerViewController.h"
#import "SCPRFlapViewController.h"
#import "SCPRProgramNavigatorViewController.h"
#import "SCPRSpinnerViewController.h"
#import "SCPREditionMineralViewController.h"
#import "SCPRSmallCutViewController.h"
#import "SCPRBreakingNewsViewController.h"

typedef enum {
  NewsPageTemplateBigTopSplitBtm,
  NewsPageTemplateSplitTopSplitBtm,
  NewsPageTemplateSingleArticle
} NewsPageTemplate;

typedef enum {
  SnapshotEditionUnknown = 0,
  SnapshotEditionMorning = 1,
  SnapshotEditionAfternoon = 2,
  SnapshotEditionEvening = 3
} SnapshotEdition;

#pragma mark - Content protocols


@protocol ContentContainer <NSObject>

@required
- (id)parentContainer;
- (id<ContentProcessor>) contentDelegate;
- (NSInteger)pageIndex;
- (UIView *)view;
- (void)handleDrillDown:(NSDictionary*)content;
- (void)unplug;

@optional
- (void)appendContentForTopic:(NSString*)topic;
- (void)setParentContiner:(id)parentContainer;

@end



@interface SCPRViewController : UIViewController<UIScrollViewDelegate,ContentProcessor,VersionCheckable,UIPopoverControllerDelegate> {
  
  SCPRPlayerWidgetViewController *_playerWidget;
  BOOL _playerDisplaying;
  
  // Title bar
  SCPRTitlebarViewController *_titleBarController;
  
  // Big UI pieces
  UIScrollView *_mainPageScroller;
  
  // Controls
  UIButton *_showOrHidePlayerButton;
  UIButton *_playLocalButton;
  UIButton *_returnToLiveButton;
  UIView *_returnToLiveSeat;
  
  // Playlist/Station : Of course these are just placeholders for experimental purposes only right now
  UIButton *_addTakeTwoButton;
  UIButton *_addOfframpButton;
  UIButton *_removeTakeTwoButton;
  UIButton *_removeOfframpButton;
  UILabel *_stationMapLabel;
  
  UIView *_whiteSheet;
  
  // Content screens
  NSMutableArray *_contentVector;
  
  // ContentProcessor
  NSMutableArray *_mediaContent;
  NSInteger _numberOfStoriesPerPage;
  
  BOOL _automating;
  
}

@property (nonatomic,strong) IBOutlet SCPRPlayerWidgetViewController *playerWidget;
@property (nonatomic,strong) IBOutlet UIButton *showOrHidePlayerButton;
@property (nonatomic,strong) IBOutlet UIButton *playLocalButton;
@property (nonatomic,strong) IBOutlet UIButton *addTakeTwoButton;
@property (nonatomic,strong) IBOutlet UIButton *addOfframpButton;
@property (nonatomic,strong) IBOutlet UIButton *removeTakeTwoButton;
@property (nonatomic,strong) IBOutlet UIButton *removeOfframpButton;
@property (nonatomic,strong) IBOutlet UILabel *stationMapLabel;
@property (nonatomic,strong) IBOutlet UIButton *returnToLiveButton;
@property (nonatomic,strong) IBOutlet UIView *returnToLiveSeat;
@property (nonatomic,strong) IBOutlet UIScrollView *mainPageScroller;
@property (nonatomic,strong) NSMutableArray *contentVector;
@property (nonatomic,strong) IBOutlet UIView *decorativeStripe;
@property (nonatomic,strong) IBOutlet SCPRTitlebarViewController *titleBarController;
@property (nonatomic,strong) UISwipeGestureRecognizer *drawerSwiper;

@property (nonatomic,strong) IBOutlet UIView *displayPortView;

#ifdef IPHONE_VERSION
  @property (nonatomic,strong) UITapGestureRecognizer *shareDrawerTapDismiss;
#endif
@property (nonatomic,strong) IBOutlet SCPRShareDrawerViewController *globalShareDrawer;
@property (nonatomic,strong) NSMutableDictionary *articlesInCategories;
@property (nonatomic,strong) NSMutableArray *backgroundFetchQueue;

@property (nonatomic,strong) id pushedContent;
@property (nonatomic,strong) IBOutlet UISegmentedControl *topicSelector;
@property (nonatomic,strong) NSMutableDictionary *pagesHashedByTopic;
@property (nonatomic,strong) id<ContentContainer> currentContainer;
@property (nonatomic,strong) SCPRProgramNavigatorViewController *programPages;
@property (nonatomic,strong) SCPRProgramNavigatorViewController *completeProgramPages;
@property (nonatomic,strong) SCPRSpinnerViewController *spinner;
@property (nonatomic,strong) SCPRSmallCutViewController *smallCutter;
@property (nonatomic,strong) IBOutlet UIImageView *globalGradient;

#ifdef IPAD_VERSION
@property (nonatomic,strong) UIPopoverController *sharePopover;
#endif



@property CGPoint capturedOffset;

// Determining type of news and formatting to display
@property (nonatomic,strong) NSString *newsPath;
@property ScreenContentType currentNewsType;

// Content Display Port
@property (nonatomic,strong) NSMutableArray *mediaContent;
@property NSInteger numberOfStoriesPerPage;

@property BOOL playerDisplaying;
@property BOOL automating;
@property BOOL shareDrawerOpen;
@property BOOL padThinContent;
@property BOOL silentlyFetchingNews;
@property BOOL onboardingFirstTime;

@property (nonatomic,strong) UIView *whiteSheet;
@property (nonatomic,strong) NSDictionary *currentAnchors;

@property (atomic) NSInteger backgroundProcessesToPend;

#ifdef DEBUG
- (void)functionThatDoesntExist;
#endif

@property (nonatomic,strong) IBOutlet UIButton *testVolumeButton;
- (IBAction)volTap:(id)sender;

- (void)workOnBackgroundFetch;

- (void)finishTransition;

- (IBAction)switchToggled:(id)sender;

- (void)globalInit;
- (void)primeUI:(ScreenContentType)contentType newsPath:(NSString*)newsPath;
- (void)cloakUI;
- (void)handleDrawerCommand:(NSString*)drawerCode;

// Content layouts
- (void)buildNewsPages:(NSMutableArray*)contentObjects;
- (void)displayProgramPage:(NSMutableArray*)contentObjects target:(NSString*)show;
- (void)displayProgramAZPage:(NSMutableArray*)contentObjects;
- (void)displaySnapshot:(NSMutableArray*)contentObjects edition:(SnapshotEdition)edition;
- (void)displaySimpleContent:(NSDictionary*)contentObjects;
- (void)displayEventsPage:(NSMutableArray*)contentObjects;
- (void)displayUserProfilePage:(NSMutableArray*)contentObjects;
- (void)displayVideoPhotoPage:(NSDictionary*)contentObjects;
- (void)displayUnderConstructionPage:(NSString*)pageTitle;
- (void)displayFeedbackPage;
- (void)displayOnboardingPage;
- (void)wipePreviousContent;
- (NSMutableArray*)stripBadContent:(NSMutableArray*)dirtyContent;
- (void)padContentGaps;

- (IBAction)buttonTapped:(id)sender;
- (void)displayPlayer;
- (void)hidePlayer;
- (void)forceHideOfReturnToLive;
- (void)buildProgramPages:(BOOL)favoritesOnly;
- (void)processProgramImagesInBackground;

- (NSString*)masterKeyForTopic:(NSString*)topic;

- (void)adjustScrollerSizeForPlayerState;

- (NSMutableDictionary*)categoryHashForArticleSet:(NSArray*)articles;
- (NSDictionary*)categoryMap;

// New page factories
- (SCPRNewsPageContainerController*)containerFor:(id<ContentContainer>)page hideStrip:(BOOL)strip;

// Automation
- (void)checkAutomation;

// Share Drawer
- (void)placeShareDrawer;
- (void)openShareDrawer:(id)targetContent;
- (void)closeShareDrawer;
- (void)toggleShareDrawer;


- (void)snapToDisplayPortWithView:(id)view;

@property CGRect originalShareDrawerFrame;

@end
