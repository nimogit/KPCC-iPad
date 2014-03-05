//
//  SCPRFloatingEmbedViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/21/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRFloatingEmbedViewController.h"
#import "global.h"
#import "SCPRCloakViewController.h"

#define kMaxEmbedHeight 600.0

@interface SCPRFloatingEmbedViewController ()

@end

@implementation SCPRFloatingEmbedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  //self.view.layer.cornerRadius = 4.0;

  self.view.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  self.view.layer.borderWidth = 1.0;
  self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
  self.volumeView.alpha = 0.1;
  [self.spinner startAnimating];
  
  [self.view addSubview:self.volumeView];
  self.view.clipsToBounds = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(movieEnteredFullscreen)
                                               name:@"UIMoviePlayerControllerDidEnterFullscreenNotification"
                                             object:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(movieExitedFullscreen)
                                               name:@"UIMoviePlayerControllerDidExitFullscreenNotification"
                                             object:nil];

    // Do any additional setup after loading the view from its nib.
}

- (void)movieEnteredFullscreen {
  [[DesignManager shared] setHasBeenInFullscreen:YES];
}

- (void)movieExitedFullscreen {

  [[Utilities del] uncloakUI];
}

- (void)deactivate {
  
  self.deactivating = YES;
  NSString *code = [NSString stringWithFormat:@"%@%d",[Utilities sha1:self.dataService],
                    (NSInteger)[[NSDate date] timeIntervalSince1970]];
  self.deactivationToken = code;
  [[ContentManager shared] queueDeactivation:self];
  
  [self.videoAssetWebView loadHTMLString:@""
                                 baseURL:nil];
  
  NSString *blank = [[FileManager shared] copyFromMainBundleToDocuments:@"blank.html"
                                                               destName:@"blank.html"];
  NSURL *url = [NSURL fileURLWithPath:blank];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                         cachePolicy:NSURLCacheStorageAllowed
                                                     timeoutInterval:10.0];
  
  [self.videoAssetWebView stopLoading];
  [self.videoAssetWebView loadRequest:request];
}

- (void)setupWithPVArticle:(NSDictionary *)pvArticle {
  
  NSArray *assets = [pvArticle objectForKey:@"assets"];
  self.pvArticle = pvArticle;
  self.videoAssetWebView.delegate = self;
  self.videoAssetWebView.alpha = 0.0;
  
  NSDictionary *primary = nil;
  NSDictionary *native = nil;
  for ( unsigned i = 0; i < [assets count]; i++ ) {
    primary = [assets objectAtIndex:i];
    native = [primary objectForKey:@"native"];
    if ( native ) {
      break;
    }
  }

  if ( !native ) {
    return;
  }
  
  NSString *type = [native objectForKey:@"type"];
  NSString *ID = [NSString stringWithFormat:@"%@",[native objectForKey:@"id"]];
  NSString *embed = @"";
  if ( [type rangeOfString:@"YoutubeVideo"].location == 0 ) {
    embed = [[FileManager shared] flatYouTubeWithId:ID
                                                        width:self.videoAssetWebView.frame.size.width-4.0
                                                       height:self.videoAssetWebView.frame.size.height-3.0];

  }
  if ( [type rangeOfString:@"VimeoVideo"].location == 0 ) {
    embed = [[FileManager shared] flatVimeoEmbedWithId:ID
                                                 width:self.videoAssetWebView.frame.size.width
                                                height:self.videoAssetWebView.frame.size.height];
  }
  /*if ( [type rangeOfString:@"BrightcoveVideo"].location == 0 ) {
    CGRect f = self.videoAssetWebView.frame;
    self.bcVideo = [[SCPRBCVideoContentViewController alloc] initWithNibName:[[DesignManager shared]
                                                                              xibForPlatformWithName:@"SCPRBCVideoContentViewController"]
                                                                      bundle:nil];
    self.bcVideo.view.frame = f;
    [self.view addSubview:self.bcVideo.view];
    
    self.bcVideo.view.center = CGPointMake(self.view.frame.size.width/2.0,self.view.frame.size.height/2.0);
    [self.bcVideo loadVideoWithID:ID];
    [self.videoAssetWebView removeFromSuperview];
  }*/
  
  [self.videoAssetWebView loadHTMLString:embed
                                 baseURL:[NSURL URLWithString:@"http://"]];
  
  NSString *headline = [primary objectForKey:@"title"];
  [self.headline sansifyTitleText:headline
                             bold:YES
                    respectHeight:YES];
  self.headline.textColor = [[DesignManager shared] consistentCharcolColor];
  
  NSString *caption = [primary objectForKey:@"caption"];
  [self.blurb italicizeText:caption bold:NO respectHeight:YES];
  
  self.blurb.textColor = [[DesignManager shared] number3pencilColor];
  [[DesignManager shared] avoidNeighbor:self.headline
                               withView:self.blurb
                              direction:NeighborDirectionAbove
                                padding:6.0];
  

  
  if ( self.fadeAudio ) {
    if ( [[AudioManager shared] isPlayingAnyAudio] ) {
      /*[[AudioManager shared] fadeAudio:^{
        self.audioWasPlaying = YES;
        [[AudioManager shared] pauseStream];
      } hard:NO];
       */
      self.audioWasPlaying = YES;
      [[AudioManager shared] pauseStream];
    }
  }
  
}

- (void)setupWithEmbed:(NSDictionary*)metaData {
  
  self.videoAssetWebView.alpha = 0.0;
  NSString *embed = [metaData objectForKey:@"embed_url"];
  NSString *dataService = [metaData objectForKey:@"data_service"];
  
  self.dataService = dataService;
  
  if ( [embed rangeOfString:@"extern_"].location != NSNotFound ) {
    NSRange protocol = [embed rangeOfString:@"://"];
    NSString *clip = [embed substringFromIndex:protocol.location];
    embed = [NSString stringWithFormat:@"http%@",clip];
  }
  
  self.videoAssetWebView.delegate = self;
  
  // DataService special handling
  if ( [self.dataService isEqualToString:@"youtube"] ) {
    embed = [[FileManager shared] flatYouTubeWithId:[self mineForYouTubeID:embed]
                                              width:self.videoAssetWebView.frame.size.width-4.0
                                             height:self.videoAssetWebView.frame.size.height-3.0];
    [self.videoAssetWebView loadHTMLString:embed
                                   baseURL:[NSURL URLWithString:@"http://"]];
    return;
  }
  if ( [self.dataService isEqualToString:@"googlemaps"] ) {
#ifdef DEBUG
    //embed = @"https://www.google.com/maps?ll=34.149245,-118.16599&spn=0.109247,0.220757&t=m&z=13";
    //embed = [embed stringByAppendingString:@"&output=embed"];
#endif
    embed = [[FileManager shared] flatEmbedWithReplacementData:embed
                                                         width:self.videoAssetWebView.frame.size.width
                                                        height:self.videoAssetWebView.frame.size.height
                                                       service:@"googlemaps"];
    NSString *file = [[FileManager shared] htmlPageFromBody:embed];
    NSURL *reqURL = [NSURL fileURLWithPath:file];
    NSURLRequest *req = [NSURLRequest requestWithURL:reqURL];
    
    /*[self.videoAssetWebView loadHTMLString:embed
                                   baseURL:[NSURL URLWithString:@"http://"]];*/
    [self.videoAssetWebView loadRequest:req];
    
    return;
  }
  
  NSURL *url = [NSURL URLWithString:embed];
  NSURLRequest *req = [NSURLRequest requestWithURL:url];
  self.videoAssetWebView.scalesPageToFit = YES;
  [self.videoAssetWebView loadRequest:req];
}

- (NSString*)mineForYouTubeID:(NSString *)url {
  return [Utilities clipOutYouTubeID:url];
}

#pragma mark - UIWebView
- (void)webViewDidFinishLoad:(UIWebView *)webView {
  
  if ( self.deactivating ) {
    if ( [self audioWasPlaying] ) {
      [[AudioManager shared] unpauseStream];
    }
    
    [self.videoAssetWebView removeFromSuperview];
    self.videoAssetWebView = nil;
    
    [[ContentManager shared] popDeactivation:self.deactivationToken];
    return;
  }
  
  if ( !self.loadedOnce ) {
    self.loadedOnce = YES;
    BOOL center = NO;
    if ( ![Utilities pureNil:self.dataService] ) {
      
      NSString *output = [self.videoAssetWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"container\").offsetHeight;"];
      CGFloat use = [output floatValue];//fmaxf([output floatValue],self.videoAssetWebView.frame.size.width);
      use = fminf(use, self.videoAssetWebView.frame.size.width);
      if ( use == self.videoAssetWebView.frame.size.width ) {
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y,
                                     use,
                                     use);
        CGRect crushed = CGRectInset(self.view.frame, 4.0, 4.0);
        self.videoAssetWebView.frame = crushed;
        
      }
      
      if ( [self.dataService isEqualToString:@"scribd"] ) {
        center = YES;
      }
      
      if ( center ) {
        self.videoAssetWebView.center = CGPointMake(self.view.frame.size.width/2.0,
                                                  self.view.frame.size.height/2.0);
      }
      
      UIView *container = [[[Utilities del] cloak] view];
      
      self.view.center = CGPointMake(container.frame.size.width/2.0,
                                     container.frame.size.height/2.0);
      
      [UIView animateWithDuration:0.22 animations:^{

        self.videoAssetWebView.alpha = 1.0;
        self.view.alpha = 1.0;
        self.spinner.alpha = 0.0;
        [self.spinner stopAnimating];
        
      }];
      
    } else {
      [UIView animateWithDuration:0.22 animations:^{
        self.view.alpha = 1.0;
        self.spinner.alpha = 0.0;
        self.videoAssetWebView.alpha = 1.0;
      }];
    }
  }
  
  self.view.backgroundColor = [UIColor whiteColor];
  

  
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
