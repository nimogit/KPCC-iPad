//
//  SCPRWebVideoContentViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 4/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SCPRWebVideoContentViewController : UIViewController<UIWebViewDelegate>

@property (nonatomic,strong) IBOutlet UIWebView *dynamicWebContentView;
@property (nonatomic,strong) NSString *jsHandler;
@property BOOL injected;
@property BOOL videoLoaded;
@property BOOL firstPlaySent;
@property (nonatomic,strong) NSString *videoFile;
@property (nonatomic,strong) NSString *requestURL;

- (void)loadContentURL:(NSURL*)address;
- (void)loadContentString:(NSString*)string;
- (void)snapFramesTo:(UIView*)view;
//- (void)playVideo:(id)video;

@end
