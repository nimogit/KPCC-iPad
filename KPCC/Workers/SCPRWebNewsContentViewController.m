//
//  SCPRWebNewsContentViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRWebNewsContentViewController.h"
#import "SCPRExternalWebContentViewController.h"
#import "global.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SBJson.h"
#import "SCPRViewController.h"
#import "SCPRFloatingEmbedViewController.h"

static NSOperationQueue *singletonContentLoadingQueue = nil;

@interface SCPRWebNewsContentViewController ()

@end

@implementation SCPRWebNewsContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

+ (NSOperationQueue*)sharedQueue {
  if ( !singletonContentLoadingQueue ) {
    @synchronized(self) {
      singletonContentLoadingQueue = [[NSOperationQueue alloc] init];
    }
  }
  
  return singletonContentLoadingQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  

	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/****************************************************************/
// -- Developer Note --
// Right now article caching is turned off. This is because sometimes errors/typos are found after an article is published so the editor will
// make a quick change and expect that change to reflect across the board. With the cache in place unfortunately there's not enough communication
// with Outpost to tell that a relevant article needs a refresh in the cache so I just disabled it. I think it's worth reviving this system somehow
// though do some experiments with load times and see if it's worth it. Last I checked the app *felt* faster when it was reloading articles from the
// cache instead of re-parsing it and rebuilding it but the savings might not actually be that great, so before devising a system where
// the cache is used, do some tests to see how much of a performance benegit we actually get from it.
//
- (void)setupWithArticle:(NSDictionary *)article delegate:(id<WebContentContainer>)delegate {
  [self.webView stopLoading];
  
  self.referenceArticle = article;
  
  self.webView.scrollView.bounces = NO;
  self.webView.scrollView.scrollEnabled = NO;
  self.delegate = delegate;
  
  if ( self.initialLoadFinished ) {
    return;
  }
  
  NSString *styled = @"";
  
#ifdef USE_ARTICLE_CACHING
  ArticleStub *stub = [[ContentManager shared] stubForArticle:article];
  if ( stub ) {
 
    NSLog(@"Found in cache ... ");
    
    self.tappableLinks = (NSDictionary*)[stub.links JSONValue];
    styled = stub.body;
    self.styledBody = styled;
    self.queuedContentString = nil;
    [self.webView loadHTMLString:styled baseURL:[NSURL URLWithString:@"http://"]];

  } else {
#endif
   
    NSString *body = /*[Utilities unwebbifyString:*/[article objectForKey:@"body"]/*]*/;
    
    if ( self.pushAsset ) {
      self.pushAsset = NO;
      NSArray *assets = [article objectForKey:@"assets"];
      if ( assets && [assets count] > 0 ) {
        NSDictionary *lead = [assets objectAtIndex:0];
        if ( ![lead objectForKey:@"native"] ) {
          body = [[FileManager shared] bodyWithInlineAsset:body
                                                     image:lead];
        }
      }
    }
    
    self.webView.delegate = self;
    NSError *error = nil;

    // To handle special content found in the html to be displayed, set self as the parsing listener as the document is being scraped
    [[FileManager shared] setListener:self];
    NSString *path = [[FileManager shared] htmlPageFromBody:body article:article];
    [[FileManager shared] setListener:nil];
    
    styled = [[NSString alloc] initWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    styled = [[FileManager shared] replaceBadAssetLinks:styled];
    
    
    self.styledBody = styled;
    self.tappableLinks = [Utilities collectTappableLinks:styled];
    
    [[ContentManager shared] persistStubForArticle:article
                                    treatedBody:styled
                                          links:self.tappableLinks];
    
    int randy = random() % 150000;
    
    NSString *finalURL = [[FileManager shared] writeFileFromData:styled
                                                      toFilename:[NSString stringWithFormat:@"article_base_%d.htm",randy]];
    self.queuedContentString = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:finalURL]
                                             cachePolicy:NSURLCacheStorageAllowed
                                         timeoutInterval:2.0];
    
    //[self.webView loadHTMLString:styled baseURL:baseURL];
    [self.webView loadRequest:request];
    
#ifdef USE_ARTICLE_CACHING
  }
#endif

  
}

- (void)setupWithArticle:(NSDictionary *)article delegate:(id<WebContentContainer>)delegate pushAsset:(BOOL)pushAsset completion:(ArticleMergedCallback)block {
  queuedBlock = block;
  self.finishWithBlock = YES;
  self.pushAsset = pushAsset;
  [self setupWithArticle:article delegate:delegate];
}

- (void)setupWithBody:(NSString *)body delegate:(id<WebContentContainer>)delegate {
  //body = [Utilities unwebbifyString:body];
  
  
  self.webView.delegate = self;
  
  NSError *error = nil;
  
  NSString *path = [[FileManager shared] htmlPageFromBody:body article:nil style:StyleTypeSingleVideo];
  NSString *styled = [[NSString alloc] initWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
  
  self.webView.scrollView.bounces = NO;
  styled = [[FileManager shared] replaceBadAssetLinks:styled];
  self.tappableLinks = [Utilities collectTappableLinks:styled];
  self.delegate = delegate;
  [self.webView loadHTMLString:styled
                       baseURL:nil];
}

#pragma mark - Parsing Listener
- (void)parserFoundItemOfInterest:(NSString *)item {
  if ( [item rangeOfString:@"twitter_"].location != NSNotFound ) {
    NSArray *comps = [item componentsSeparatedByString:@"_"];
    self.containsTwitterEntries = YES;
    if ( !self.twitterEmbeds ) {
      self.twitterEmbeds = [[NSMutableArray alloc] init];
    }
    if ( [comps count] > 1 ) {
      [self.twitterEmbeds addObject:[comps objectAtIndex:1]];
    }
  }
}

#pragma mark - Video entered fullscreen
- (void)movieEnteredFullscreen {
  //[[DesignManager shared] setHasBeenInFullscreen:YES];
}

- (void)movieExitedFullscreen {
  //[self nudge];
}

- (void)nudge {
  SCPRViewController *scpr = [[Utilities del] viewController];
  [scpr.view setNeedsLayout];
  
  [UIView animateWithDuration:0.22 animations:^{
    scpr.view.frame = CGRectMake(scpr.view.frame.origin.x,
                                 20.0,
                                 scpr.view.frame.size.width,
                                 scpr.view.frame.size.height);
  }];

  

}

- (void)nudgeBack {
  SCPRViewController *scpr = [[Utilities del] viewController];
  scpr.view.frame = CGRectMake(scpr.view.frame.origin.x,
                               scpr.view.frame.origin.y-20.0,
                               scpr.view.frame.size.width,
                               scpr.view.frame.size.height);
}

#pragma mark - WebContent
/***************************************************************************/
// -- Developer Note --
// There's a lot going on in this shouldStartLoadWithRequest implementation. Basically the delegate is searching for embeds that have been treated
// for the app specifically. The way the embed is handled depends on the way it's been setup in the file embedsupport.json . Specific data-service
// types have been assigned an EmbedSupport value (see the enum definition) to decide how to handle certain embeds. Default behavior is to open
// an inline webview for the external content, but this is overridden by certain data services.
//
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  
  if ( self.cleaningUp ) {
    return YES;
  }
  
  NSString *urlString = [[request URL] absoluteString];
  NSRange relevantRange = [urlString rangeOfString:@"extern_"];
  if ( relevantRange.location != NSNotFound ) {
    
    urlString = [urlString substringFromIndex:relevantRange.location];
    // Punt out to Safari by default for now, to do in the future would be to make url-specific handling
    
    EmbedSupport support = [self floatingSupport:urlString];
    switch (support) {
      case EmbedSupportDisplayTwitterWithJavascript:
      {
        NSString *tid = [[urlString componentsSeparatedByString:@"/"] lastObject];
        NSLog(@"Going to oEmbed style : %@",tid);
        
        [[SocialManager shared] synthesizeTwitterTweet:tid
                                             container:self];
        
        return NO;
      }
      case EmbedSupportInlineFadeAudio:
      case EmbedSupportInlineRetainAudio:
      {
        SCPRFloatingEmbedViewController *fEmbed = [[SCPRFloatingEmbedViewController alloc]
                                                   initWithNibName:[[DesignManager shared]
                                                                    xibForPlatformWithName:@"SCPRFloatingEmbedViewController"]
                                                   bundle:nil];
        fEmbed.fadeAudio = support == EmbedSupportInlineFadeAudio;
        [[Utilities del] cloakUIWithCustomView:fEmbed dismissible:YES];
        [fEmbed setupWithEmbed:@{ @"embed_url" : urlString, @"data_service" : [self extractDataService:urlString]}];
      }
        break;
      case EmbedSupportPuntToSafari:
      {
        NSRange r = [urlString rangeOfString:@"://"];
        NSString *sub = [urlString substringFromIndex:r.location+r.length];
        NSString *prefix = @"http://";
        if ( [urlString rangeOfString:@"extern_ssl"].location != NSNotFound ) {
          prefix = @"https://";
        }
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",prefix,sub]];
        [[UIApplication sharedApplication] openURL:url];
      }
        
        break;
      case EmbedSupportInlineFullWebView:
        [self.delegate externalWebContentRequest:request];
        break;
        
      default:
        break;
    }
    
    return NO;
    
  }
  
  if ( [urlString rangeOfString:@"youtube.com"].location != NSNotFound ) {
    return YES;
  }
  
  if ( [urlString rangeOfString:@"scprvideo://"].location != NSNotFound ) {
    
    NSArray *components = [urlString componentsSeparatedByString:@"//"];
    if ( components.count < 2 ) {
      NSLog(@"Bad Callout");
      return NO;
    }
    
    NSString *message = [components objectAtIndex:1];
    NSString *player = [components objectAtIndex:2];
    NSLog(@"Message is %@ and player is %@",message,player);
    if ( [message isEqualToString:@"player_playing"] ) {
      
      if ( [[AudioManager shared] isPlayingAnyAudio] ) {
        self.videoStarted = YES;
        [[AudioManager shared] pauseStream];
      }
      
    }
    if ( [message isEqualToString:@"ended"] ) {
      [self performSelectorOnMainThread:@selector(unlockAudioStream)
                             withObject:nil
                          waitUntilDone:NO];
    }
    
    return NO;
    
  }
  
  if ( !self.initialLoadFinished ) {
    return YES;
  }
  
  
  if ( [self.tappableLinks objectForKey:urlString] ) {
    [self.delegate externalWebContentRequest:request];
    return NO;
  }
  
  return YES;
  
}

- (EmbedSupport)floatingSupport:(NSString *)protocol {
  
  NSString *ds = [self extractDataService:protocol];
  NSDictionary *supported = (NSDictionary*)[Utilities loadJson:@"embedsupport"];
  
  NSNumber *n = [supported objectForKey:ds];
  if ( n ) {
    return (EmbedSupport)[n intValue];
  }
  
  return EmbedSupportInlineFadeAudio;
}

- (NSString*)extractDataService:(NSString *)url {
  
  NSRange pcl = [url rangeOfString:@"://"];
  if ( pcl.location == NSNotFound ) {
    return @"unknown";
  }
  
  NSString *clipped = [url substringToIndex:pcl.location];
  NSArray *components = [clipped componentsSeparatedByString:@"_"];
  
  return [components lastObject];
}

- (void)resumePlay {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"app_uncloaked"
                                                object:nil];
  
  NSString *callback = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"forcePlay('%@');",self.queuedPlayer]];
  NSLog(@"Callback from forcePlay : %@",callback);
  
  if ( [[AudioManager shared] streamPlaying] ) {
    self.videoStarted = YES;
    [[AudioManager shared] pauseStream];
  }
}

- (void)unlockAudioStream {
  if ( self.videoStarted ) {
    self.videoStarted = NO;
    [[AudioManager shared] startStream:nil];
  }
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
  
  if ( self.cleaningUp ) {

    NSLog(@"Finished cleanup for : %@",[self.referenceArticle objectForKey:@"title"]);
    [[ContentManager shared] printCacheUsage];
    self.cleaningUp = NO;
    if ( self.delegate ) {
      [self.delegate cleanup];
    }
    return;
  }
  
  BOOL firstTime = NO;
  if ( !self.initialLoadFinished && !self.queuedContentString ) {
    self.initialLoadFinished = YES;
    firstTime = YES;
    self.queuedContentString = nil;
  } else {
    
  }
  
  if ( firstTime ) {
    [self.delegate webContentLoaded:firstTime];
  }
  
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"Error on web content load : %@",[error localizedDescription]);
  if ( self.cleaningUp ) {
    NSLog(@" **** // This happened while cleaning up \\ ****");
  }
  [self.delegate webContentFailed];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"**** DEALLOCATING WEBVIEW WORKER **** : %@",[self.referenceArticle objectForKey:@"short_title"]);
}
#endif

@end
