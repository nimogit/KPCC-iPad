//
//  SCPRDFPViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 10/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GADInterstitial.h"

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

@interface SCPRDFPViewController : UIViewController<UIWebViewDelegate>

@property (nonatomic,strong) IBOutlet UIWebView *adView;

@property (nonatomic,weak) id<SCPRDFPAdDelegate> delegate;
@property BOOL loadLock;
@property BOOL failedOnce;
@property (nonatomic,strong) NSURLRequest *adRequest;
@property (nonatomic,strong) NSTimer *absoluteFinishTimer;
@property NSInteger loadCount;
@property (nonatomic,strong) IBOutlet UILabel *adLoadingLabel;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;

- (void)loadDFPAd;
- (void)fail;

@end
