//
//  SCPRFloatingEmbedViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/21/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRAppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
#import "global.h"
#import "SCPRBCVideoContentViewController.h"

@interface SCPRFloatingEmbedViewController : UIViewController<Cloakable,UIWebViewDelegate,Deactivatable>

@property (nonatomic,strong) IBOutlet UIWebView *videoAssetWebView;
@property (nonatomic,strong) NSDictionary *pvArticle;
@property (nonatomic,strong) IBOutlet UILabel *headline;
@property (nonatomic,strong) IBOutlet UILabel *blurb;
@property (nonatomic,strong) MPVolumeView *volumeView;
@property (nonatomic,strong) NSString *dataService;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic,strong) NSString *deactivationToken;
@property (nonatomic,strong) SCPRBCVideoContentViewController *bcVideo;

@property BOOL audioWasPlaying;
@property BOOL fadeAudio;
@property BOOL loadedOnce;
@property BOOL deactivating;

- (void)setupWithPVArticle:(NSDictionary*)pvArticle;
- (void)setupWithEmbed:(NSDictionary*)metaData;
- (NSString*)mineForYouTubeID:(NSString*)url;


@end
