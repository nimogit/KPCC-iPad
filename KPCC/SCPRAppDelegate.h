//
//  SCPRAppDelegate.h
//  KPCC
//
//  Created by Ben on 4/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"


typedef void (^VoidBlock)(void);

@class SCPRScrollingAssetViewController;
@class SCPRViewController;
@class SCPRDrawerViewController;
@class SCPRPlayerWidgetViewController;
@class SCPRTitlebarViewController;
@class SCPRShareDrawerViewController;
@class SCPRSpinnerViewController;
@class SCPRMasterRootViewController;
@class SCPRCloakViewController;

@protocol OptionsDelegate;

typedef enum {
  PushTypeUnknown = 0,
  PushTypeBreakingNews,
  PushTypeEvents
} PushType;

@protocol Cloakable <NSObject>

- (void)deactivate;

@end

@protocol Backable <NSObject>

- (void)backTapped;

@optional
- (UIScrollView*)titlebarTraversalScroller;
- (CGFloat)traversableTitlebarArea;

@end

@protocol Rotatable <NSObject>

- (void)handleRotationPre;
- (void)handleRotationPost;

@end

@interface SCPRAppDelegate : UIResponder <UIApplicationDelegate> {
  SCPRDrawerViewController *_globalDrawer;
  BOOL _drawerOpen;
  BOOL _appCloaked;
}

- (void)armGlobalDismiss:(id)sender;
- (void)disarmGlobalDismiss;
- (void)openDrawer;
- (void)closeDrawer;
- (void)toggleDrawer;
- (void)rotateDrawerForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)blackoutCloak:(VoidBlock)cloakAppeared;
- (void)cloakUIWithMessage:(NSString*)message;
- (void)cloakUIWithSlideshowFromArticle:(NSDictionary*)article;
- (void)cloakUIWithCustomView:(id<Cloakable>)controller;
- (void)cloakUIWithCustomView:(id<Cloakable>)controller dismissible:(BOOL)dismissible;
- (void)cloakUIWithCustomView:(id<Cloakable>)controller dismissible:(BOOL)dismissible push:(CGFloat)push;
- (void)cloakUIWithMessage:(NSString *)message andUnfreezeString:(NSString*)string;

- (void)uncloakUI;
- (void)uncloakUI:(BOOL)blackout;

- (void)uncloakBlackoutUI;
- (void)hideTitleBar;
- (void)showTitleBar;
- (void)dropOnWindow:(UIView*)view fromView:(UIView*)originalView animateToFrame:(CGRect)animateToFrame completion:(VoidBlock)completion;
- (void)incrementNewItemCount;

- (SCPRPlayerWidgetViewController*)globalPlayer;
- (SCPRTitlebarViewController*)globalTitleBar;

@property BOOL drawerOpen;
@property BOOL appCloaked;
@property BOOL safeCloak;
@property BOOL launchFinished;
@property PushType operatingWithPushType;
@property BOOL serverDown;
@property BOOL passiveProgramCheck;
@property BOOL oneTimeDrawerException;
@property BOOL messageShowing;
@property BOOL backgrounding;
@property BOOL appIsShowingTour;
@property BOOL firstLaunchAndDisplayFinished;
@property BOOL drawerIsDirty;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SCPRViewController *viewController;
@property (strong, nonatomic) SCPRMasterRootViewController *masterRootController;
@property (strong, nonatomic) UITapGestureRecognizer *tapper;
@property (strong, nonatomic) SCPRDrawerViewController *globalDrawer;
@property (strong, nonatomic) SCPRCloakViewController *cloak;
@property (strong, nonatomic) NSString *unfreezeKey;
@property (strong, nonatomic) SCPRScrollingAssetViewController *slideshowModal;
@property (nonatomic, strong) id<Cloakable> customCloak;
@property (nonatomic, strong) UIImageView *bigShadow;
@property (nonatomic, strong) SCPRSpinnerViewController *globalSpinner;

@end
