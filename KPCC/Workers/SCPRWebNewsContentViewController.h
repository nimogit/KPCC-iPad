//
//  SCPRWebNewsContentViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

typedef void (^ArticleMergedCallback)(void);

typedef enum {
  EmbedSupportUnknown = 0,
  EmbedSupportInlineFadeAudio = 1,
  EmbedSupportInlineRetainAudio = 2,
  EmbedSupportInlineFullWebView = 3,
  EmbedSupportPuntToSafari = 4,
  EmbedSupportDisplayTwitterWithJavascript = 5
} EmbedSupport;

@protocol WebContentContainer <NSObject>

@required

- (void)webContentLoaded:(BOOL)firstTime;
- (void)webContentFailed;

@optional
- (BOOL)webContentReady;
- (void)refreshHeight;
- (void)cleanup;
- (NSDictionary*)associatedArticleContent;
- (void)externalWebContentRequest:(NSURLRequest*)request;

@end

typedef void (^ContentLoadingBlock)(void);

@interface SCPRWebNewsContentViewController : UIViewController<UIWebViewDelegate,ParsingListener> {
  ArticleMergedCallback queuedBlock;
}

@property (nonatomic,strong) IBOutlet UIWebView *webView;
@property BOOL firstPlaySent;
@property BOOL videoStarted;
@property BOOL initialLoadFinished;
@property BOOL videoEnteredFullScreen;
@property BOOL loadingSkeletonContent;
@property BOOL finishWithBlock;
@property BOOL pushAsset;
@property BOOL cleaningUp;
@property BOOL containsTwitterEntries;
@property (nonatomic,strong) NSDictionary *referenceArticle;
@property (nonatomic,strong) NSString *queuedPlayer;
@property (nonatomic,strong) NSDictionary *tappableLinks;
@property (nonatomic,weak) id<WebContentContainer> delegate;
@property (nonatomic,strong) id externalContent;
@property (nonatomic,strong) NSString *contentHint;
@property (nonatomic,strong) NSString *queuedContentString;
@property (nonatomic,strong) NSString *styledBody;
@property (nonatomic,strong) NSMutableArray *twitterEmbeds;

+ (NSOperationQueue*)sharedQueue;

- (void)setupWithArticle:(NSDictionary*)article delegate:(id<WebContentContainer>)delegate;
- (void)setupWithArticle:(NSDictionary *)article delegate:(id<WebContentContainer>)delegate pushAsset:(BOOL)pushAsset completion:(ArticleMergedCallback)block;
- (void)setupWithBody:(NSString*)body delegate:(id<WebContentContainer>)delegate;
- (EmbedSupport)floatingSupport:(NSString*)protocol;
- (NSString*)extractDataService:(NSString*)url;

@end
