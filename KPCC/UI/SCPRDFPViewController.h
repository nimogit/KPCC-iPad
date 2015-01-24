//
//  SCPRDFPViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 10/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADInterstitial.h"
#import "ContentManager.h"

typedef enum {
  DismissDirectionLeft = 0,
  DismissDirectionRight
} DismissDirection;

@protocol SCPRDFPAdDelegate <NSObject>

@required
- (void)adDidFinishLoading;
- (void)adWillDismiss:(DismissDirection)direction;
- (void)armDismissal;
- (void)disarmDismissal;

@optional
- (void)adDidFail;

@end

@interface SCPRDFPViewController : UIViewController<UIWebViewDelegate,Pageable>

@property (nonatomic,strong) IBOutlet UIWebView *adView;

@property (nonatomic,weak) id<SCPRDFPAdDelegate> delegate;
@property BOOL loadLock;
@property BOOL failedOnce;
@property (nonatomic,strong) NSURLRequest *adRequest;
@property (nonatomic,strong) NSTimer *absoluteFinishTimer;
@property NSInteger loadCount;
@property NSInteger index;
@property (nonatomic,strong) IBOutlet UILabel *adLoadingLabel;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic,strong) UISwipeGestureRecognizer *leftSwiper;
@property (nonatomic,strong) UISwipeGestureRecognizer *rightSwiper;
@property (nonatomic,strong) UIPanGestureRecognizer *panner;


- (void)loadDFPAd;
- (void)fail;
- (void)armSwipers;

@end
