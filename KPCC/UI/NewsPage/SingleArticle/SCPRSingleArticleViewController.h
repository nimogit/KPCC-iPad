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
#import "SCPRScrollingAssetViewController.h"
#import "SCPRWebNewsContentViewController.h"
#import "SCPRFlapViewController.h"
#import "SCPRViewController.h"
#import "SCPRFloatingEmbedViewController.h"
#import "SCPREditionAtomViewController.h"
#import "SCPRGrayLineView.h"

@class SCPRHBTView;
@class SCPRNewsPageViewController;

@interface SCPRSingleArticleViewController : UIViewController<ContentProcessor,UIWebViewDelegate,UIAlertViewDelegate,Backable,WebContentContainer,Deactivatable,Rotatable>


@property (nonatomic,strong) NSDictionary *relatedArticle;
@property (nonatomic,strong) NSString *relatedURL;
@property (nonatomic,strong) NSString *deactivationToken;
@property NSInteger numberOfStoriesPerPage;
@property CGRect originalWebViewHeight;
@property (nonatomic,strong) NSTimer *captionFadeTimer;
@property (nonatomic,strong) UITapGestureRecognizer *captionFadeTapper;


// UI elements and IBOutlets
@property (nonatomic,strong) IBOutlet UIWebView *webView;
@property (nonatomic,strong) IBOutlet UIScrollView *masterContentScroller;
@property (nonatomic,strong) IBOutlet SCPRHBTView *basicTemplate;
@property (nonatomic,strong) IBOutlet UIView *textSheetView;
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
@property (nonatomic,strong) IBOutlet UIView *landscapeImageSheetView;
@property (nonatomic,strong) IBOutlet UIButton *queueButton;


// Photo & Video
@property (nonatomic,strong) IBOutlet UIWebView *videoAssetWebView;
@property (nonatomic,strong) IBOutlet UIButton *playOverlayButton;
@property (nonatomic,strong) IBOutlet UIButton *slideshowOverlayButton;

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
@property BOOL hasSocialData;
@property BOOL shareModalOpen;
- (void)socialDataLoaded;
- (void)toggleShareModal;
- (void)closeShareModal;
- (void)openShareModal;
@property (nonatomic,strong) UIPopoverController *shareModal;
@property (nonatomic,strong) IBOutlet SCPRShareDrawerViewController *shareDrawer;
- (void)queryParse;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bylineToCaptionAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *grayLineToByLineAnchor;

@property NSInteger index;
@property BOOL videoStarted;
@property BOOL initialLoadFinished;
@property BOOL fromSnapshot;
@property BOOL workerThread;
@property BOOL contentArranged;
@property BOOL gateOpen;
@property BOOL needsShareOpen;


@property BOOL captionUp;
@property BOOL okToDelete;
@property BOOL liveEvent;
@property BOOL shortPage;
@property BOOL twitterSynthesized;
@property BOOL pushAssetIntoBody;

@property BOOL untouchable;


#pragma mark - Content Display Port
@property (nonatomic,strong) NSMutableArray *mediaContent;
@property (nonatomic,strong) NSMutableDictionary *singleMediaContent;


@property BOOL okToTrash;
@property (nonatomic,weak) SCPRNewsPageViewController *parentNewsPage;
@property (nonatomic,strong) SCPRScrollingAssetViewController *extraAssetsController;
@property (nonatomic,strong) IBOutlet SCPRWebNewsContentViewController *webContentLoader;
@property (nonatomic,strong) SCPRFloatingEmbedViewController *floatingVideoController;

@property (nonatomic,weak) id<ContentProcessor> supplementalContainer;
@property (nonatomic,weak) id parentCollection;
@property (nonatomic,strong) id externalContent;
@property (nonatomic,weak) id parentEditionAtom;


@property (nonatomic, strong) IBOutlet NSLayoutConstraint *webContentHeightAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *articleDetailsAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *grayLineBottomAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *playerControlsByLineAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *webViewBottomAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *webViewTopAnchor;


- (IBAction)buttonTapped:(id)sender;
- (void)arrangeContent;
- (void)adjustUIForQueue:(NSNotification*)note;

- (void)killContent;
- (void)safeKillContent;

- (void)snapToContentHeight;
- (void)handleDelayedLoad;
- (void)photoVideoTreatment;
- (void)presentVideo;
- (void)armCaption:(NSDictionary*)leadingAsset;
- (void)shortenForNoAudio;

@end
