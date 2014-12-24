//
//  SCPRMasterRootViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRQueueViewController.h"
#import "global.h"
#import "SCPRDFPViewController.h"
#import "GADInterstitial.h"
#import "SCPRBreakingNewsViewController.h"
#import "SCPRDFPViewController.h"

typedef void (^AdKilledCompletion)(void);

@interface SCPRMasterRootViewController : UIViewController<Rotatable,GADInterstitialDelegate,ContentProcessor,UIAlertViewDelegate,SCPRDFPAdDelegate>

@property NSInteger screenContentType;
@property (nonatomic,strong) IBOutlet UIImageView *globalGradient;
@property (nonatomic,strong) IBOutlet SCPRQueueViewController *queueViewController;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) SCPRDFPViewController *adMobViewController;
@property (nonatomic,strong) GADInterstitial *interstitial;
@property (nonatomic,strong) IBOutlet SCPRBreakingNewsViewController *breakingNewsOverlay;
@property (nonatomic,strong) id pushedContent;
@property (nonatomic,strong) SCPRDFPViewController *dfpAdViewController;
@property (nonatomic,weak) UIView *adPresentationView;


@property (nonatomic,strong) IBOutlet UILabel *hudInformationLabel;

@property BOOL queueUp;
@property BOOL breakingNewsShowing;
@property BOOL introDisplaying;

@property CGFloat savedYOffset;

@property UIInterfaceOrientation frozenOrientation;

- (void)bringUpQueue;
- (void)hideQueue;
- (void)invalidateStatusBar;
- (void)showIntro;
- (void)hideIntro;
- (void)cloak;
- (void)cloak:(BOOL)spinner;
- (void)fullCloak;
- (void)uncloak;
- (void)preserveAd;

// Ads
- (void)deliverAd:(UISwipeGestureRecognizerDirection)direction intoView:(UIView*)scroller;
- (void)deliverAd:(UISwipeGestureRecognizerDirection)direction intoView:(UIView *)scroller silence:(NSMutableArray*)silenceVector;
- (void)undeliverAd;
- (void)killAdOffscreen:(AdKilledCompletion)completion;
- (void)killAdOnscreen:(AdKilledCompletion)completion;

@property (nonatomic,strong) NSMutableArray *adSilenceVector;
@property (nonatomic,strong) UISwipeGestureRecognizer *dismissLeft;
@property (nonatomic,strong) UISwipeGestureRecognizer *dismissRight;

// Breaking news
- (void)showBreakingNewsWithMessage:(NSString*)message action:(BreakingInteractionCallback)callback;
- (void)hideBreakingNews;
- (void)displayAtomicArticleWithURL:(NSString*)url;
- (void)puntToSafariWithURL:(NSString*)url;

@end
