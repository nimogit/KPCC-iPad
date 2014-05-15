//
//  SCPRSingleArticleViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRFlatShadedButton.h"
#import "SCPRArmoireViewController.h"
#import "SCPRScrollingAssetViewController.h"
#import "SCPRWebNewsContentViewController.h"
#import "SCPRFlapViewController.h"
#import "SCPRViewController.h"
#import "SCPRFloatingEmbedViewController.h"
#import "SCPREditionAtomViewController.h"
#import "SCPRGrayLineView.h"

@class SCPRHBTView;
@class SCPRNewsPageViewController;

@interface SCPRSingleArticleViewController : UIViewController<ContentProcessor,UIWebViewDelegate,UIAlertViewDelegate,Backable,WebContentContainer,Turnable,Deactivatable,Rotatable>

@property (nonatomic,strong) IBOutlet UIScrollView *contentScroller;
@property (nonatomic,strong) IBOutlet UIButton *backButton;
@property (nonatomic,strong) IBOutlet UIWebView *webView;
@property (nonatomic,strong) IBOutlet UIScrollView *spilloverScroller;
@property (nonatomic,strong) IBOutlet UIScrollView *masterContentScroller;
@property (nonatomic,strong) IBOutlet SCPRHBTView *basicTemplate;
@property (nonatomic,strong) NSDictionary *relatedArticle;
@property (nonatomic,strong) NSString *relatedURL;
@property (nonatomic,strong) IBOutlet UIView *textSheetView;
@property (nonatomic,strong) UIView *shadowView;
@property (nonatomic,weak) UIScrollView *observableScroller;

@property (nonatomic,strong) IBOutlet SCPRGrayLineView *contentDividerLine;
@property (nonatomic,strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic,strong) IBOutlet UIView *categorySeat;
@property (nonatomic,strong) IBOutlet UIView *extraAssetsSeat;
@property (nonatomic,strong) IBOutlet UIImageView *extraAssetsImage;
@property (nonatomic,strong) IBOutlet UILabel *extraAssetsLabel;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) IBOutlet UIView *audioSeatView;
@property (nonatomic,strong) IBOutlet UIButton *playAudioButton;
@property (nonatomic,strong) IBOutlet UIButton *addAudioToQueueButton;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *audioDividerLine;
@property (nonatomic,strong) IBOutlet UILabel *playThisAudioLabel;
@property (nonatomic,strong) IBOutlet UILabel *audioDurationLabel;
@property (nonatomic,strong) IBOutlet UIView *audioSeatInternalView;
@property (nonatomic,strong) UIButton *captionButton;
@property (nonatomic,strong) IBOutlet UIView *captionView;
@property (nonatomic,strong) IBOutlet UILabel *captionLabel;
@property (nonatomic,strong) IBOutlet UILabel *captionCreditLabel;
@property (nonatomic,strong) IBOutlet UIView *rsvpSeatView;
@property (nonatomic,strong) IBOutlet UIView *rsvpButtonSeatView;
@property (nonatomic,strong) IBOutlet UILabel *dateCaptionLabel;
@property (nonatomic,strong) IBOutlet UILabel *locationCaptionLabel;
@property (nonatomic,strong) IBOutlet UILabel *dateContentLabel;
@property (nonatomic,strong) IBOutlet UILabel *locationContentLabel;
@property (nonatomic,strong) IBOutlet UIButton *rsvpButton;

// Social data, views and methods
@property (nonatomic,strong) IBOutlet UIView *socialSheetView;
@property (nonatomic,strong) IBOutlet UIView *socialShareView;
@property (nonatomic,strong) IBOutlet UILabel *facebookCountLabel;
@property (nonatomic,strong) IBOutlet UILabel *twitterCountLabel;
@property (nonatomic,strong) IBOutlet UIImageView *facebookLogoImage;
@property (nonatomic,strong) IBOutlet UIImageView *twitterLogoImage;
@property (nonatomic,strong) IBOutlet UIView *socialLineDivider;
@property (nonatomic,strong) IBOutlet UIButton *socialShareButton;
@property (nonatomic,strong) NSMutableDictionary *socialCountHash;
- (void)socialDataLoaded;
- (void)toggleShareModal;
@property BOOL hasSocialData;
@property BOOL shareModalOpen;
- (void)closeShareModal;
- (void)openShareModal;
@property (nonatomic,strong) UIPopoverController *shareModal;
@property (nonatomic,strong) IBOutlet SCPRShareDrawerViewController *shareDrawer;
- (void)queryParse;

@property (nonatomic,strong) IBOutlet UIView *landscapeImageSheetView;

@property (nonatomic,strong) NSTimer *captionFadeTimer;
@property (nonatomic,strong) UITapGestureRecognizer *captionFadeTapper;

@property BOOL captionUp;
@property BOOL okToDelete;
@property BOOL liveEvent;
@property BOOL shortPage;
@property BOOL twitterSynthesized;

#pragma mark - Content Display Port
@property (nonatomic,strong) NSMutableArray *mediaContent;
@property (nonatomic,strong) NSMutableDictionary *singleMediaContent;

@property NSInteger numberOfStoriesPerPage;

@property (nonatomic,strong) IBOutlet UIButton *queueButton;
@property BOOL okToTrash;
@property (nonatomic,weak) SCPRNewsPageViewController *parentNewsPage;
@property (nonatomic,strong) SCPRArmoireViewController *armoireController;
@property (nonatomic,strong) SCPRScrollingAssetViewController *extraAssetsController;
@property (nonatomic,strong) IBOutlet SCPRWebNewsContentViewController *webContentLoader;
@property (nonatomic,strong) SCPRFloatingEmbedViewController *floatingVideoController;

@property (nonatomic,weak) id parentCollection;
@property (nonatomic,strong) id externalContent;
@property (nonatomic,weak) id parentEditionAtom;

@property (nonatomic,strong) SCPRFlapViewController *leftFlap;
@property (nonatomic,strong) SCPRFlapViewController *rightFlap;

@property (nonatomic,strong) UIView *matteCloak;
@property (nonatomic,strong) UIView *sheetCloak;
@property NSInteger index;
@property NSInteger ghostIndex;
@property BOOL firstPlaySent;
@property BOOL videoStarted;
@property BOOL initialLoadFinished;
@property BOOL gateOpen;
@property BOOL pageBeingDestroyed;
@property BOOL fromSnapshot;
@property BOOL assetsHandled;
@property BOOL workerThread;
@property BOOL contentArranged;
@property (nonatomic,strong) NSString *styled;
@property CGRect ghostFrame;
@property (nonatomic,strong) NSString *queuedPlayer;

@property (nonatomic,strong) NSTimer *bandFadeTimer;
@property (nonatomic,strong) UITapGestureRecognizer *tapper;

// Photo & Video
@property (nonatomic,strong) IBOutlet UIView *imageCloak;
@property (nonatomic,strong) IBOutlet UIWebView *videoAssetWebView;
@property (nonatomic,strong) IBOutlet UIButton *playOverlayButton;
@property (nonatomic,strong) IBOutlet UIButton *slideshowOverlayButton;

@property (nonatomic,weak) id<ContentProcessor> supplementalContainer;

@property BOOL postProcessed;
@property BOOL isPhotoVideo;

@property CGRect originalWebViewHeight;

@property (nonatomic,strong) NSString *deactivationToken;

- (IBAction)buttonTapped:(id)sender;
- (void)arrangeContent;
- (NSString*)smartSplit:(NSString*)fullString givenLabel:(UILabel*)label;
- (void)adjustUIForQueue:(NSNotification*)note;
- (void)partialWash;
- (void)unwash;
- (void)handleMultipleAssets;

- (void)killContent;
- (void)safeKillContent;

- (void)snapToContentHeight;
- (void)handleDelayedLoad;
- (void)arm;
- (void)postProcess;
- (void)photoVideoTreatment;
- (void)presentVideo;
- (void)armCaption:(NSDictionary*)leadingAsset;

@end
