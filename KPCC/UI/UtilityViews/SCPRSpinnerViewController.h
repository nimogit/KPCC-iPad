//
//  SCPRSpinnerViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^SpinnerAppearedBlock)(void);

@interface SCPRSpinnerViewController : UIViewController<UIWebViewDelegate>

- (void)spinWithFinishedToken:(NSString*)token inView:(UIView*)view;
- (void)spinWithFinishedToken:(NSString *)token inView:(UIView *)view pushUp:(BOOL)pushUp;
- (void)spinWithFinishedToken:(NSString *)token inView:(UIView *)view appeared:(SpinnerAppearedBlock)appeared;
- (void)spinInPlaceWithFinishedToken:(NSString*)token;

- (void)arm;
- (void)rotate;
- (void)rotate:(SpinnerAppearedBlock)block;

@property CGFloat currentAngle;
@property (nonatomic,strong) NSTimer *spinTimer;
@property (nonatomic,strong) IBOutlet UIWebView *webSpinner;
@property (nonatomic,strong) IBOutlet UIImageView *nativeSpinner;
@property BOOL stopRequested;
@property BOOL firstTurnOccurred;
@property BOOL inPlace;
@property BOOL notificationFired;
@property BOOL blue;

@end
