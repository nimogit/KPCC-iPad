//
//  SCPRVideoCompositeViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRVideoCompositeViewController.h"
#import "SCPRWebVideoContentViewController.h"
#import "SCPRBCVideoContentViewController.h"

#import "global.h"

@interface SCPRVideoCompositeViewController ()

@end

@implementation SCPRVideoCompositeViewController

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
/*
  CGRect frm = self.bannerAd.frame;
  [self.bannerAd removeFromSuperview];
  
  GADAdSize custom = GADAdSizeFromCGSize(CGSizeMake(728.0, 237.0));

  
  self.bannerAd = [[DFPBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape
                                                 origin:frm.origin];
  self.bannerAd.validAdSizes = @[
                                  [NSValue valueWithBytes:&custom
                                                 objCType:@encode(GADAdSize)] ];
  self.bannerAd.delegate = self;
  self.bannerAd.rootViewController = self;
  self.bannerAd.adUnitID = @"/127204706/TEST_iPad_UnitV1";
  [self.view addSubview:self.bannerAd];
  
  NSString *file = [[NSBundle mainBundle] pathForResource:@"webdfp"
                                                   ofType:@"html"];
  
  
  NSURL *url = [NSURL fileURLWithPath:file];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [self.webBanner loadHTMLString:html
                         baseURL:nil];
  self.webBanner.delegate = self;
  [self.webBanner loadRequest:request];*/
  
  
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
 /* GADRequest *request = [GADRequest request];
  request.testDevices = [NSArray arrayWithObjects:@"9af16039c50a240e132f47e55da6bba2",@"GAD_SIMULATOR_ID", nil];
  request.testing = YES;
  [self.bannerAd loadRequest:request];*/
}

- (void)viewDidDisappear:(BOOL)animated {

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
/*
  if ( webView == self.webBanner ) {
    if ( self.count < kInitialCount ) {
      self.count++;
      return YES;
    } else {
      
      NSLog(@"Request is %@",[[request URL] absoluteString]);
      [[[UIAlertView alloc] initWithTitle:@"Would Load Ad"
                                 message:@"This would load an external page with ad content"
                                delegate:nil
                       cancelButtonTitle:@"OK"
                        otherButtonTitles:nil] show];
      return NO;
    }
  }
  
  return YES;*/
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"Banner request seemed to be ok");

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"UH OH! : %@",[error localizedDescription]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadVideoContent:(NSArray *)content {
 /* int count = 0;
  
  self.contentVector = [[NSMutableArray alloc] init];
  self.scroller.contentSize = CGSizeMake(self.scroller.frame.size.width,
                                         0.0);
  
  for ( NSString *video in content ) {
    if ( [video rangeOfString:@"currentvideo"].location != NSNotFound ) {
      
      // Vimeo or YouTube
      SCPRWebVideoContentViewController *wvc = [[SCPRWebVideoContentViewController alloc]
                                                initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPRWebVideoContentViewController"]
                                                bundle:nil];
      [self.contentVector addObject:wvc];

      wvc.view.frame = CGRectMake(0.0,count*wvc.view.frame.size.height,
                                  wvc.view.frame.size.width,
                                  wvc.view.frame.size.height);
      
      [self.scroller addSubview:wvc.view];
      [wvc loadContentString:video];
      
      self.scroller.contentSize = CGSizeMake(self.scroller.contentSize.width,
                                             self.scroller.contentSize.height+wvc.view.frame.size.height);
    }
    if ( [video rangeOfString:@"brightcove"].location != NSNotFound ) {
      
      // Brightcove
      SCPRBCVideoContentViewController *bcv = [[SCPRBCVideoContentViewController alloc]
                                               initWithNibName:[[DesignManager shared]
                                                                xibForPlatformWithName:@"SCPRBCVideoContentViewController"]
                                               bundle:nil];
      
      [self.contentVector addObject:bcv];
      
      bcv.view.frame = CGRectMake(0.0,count*bcv.view.frame.size.height,
                                  bcv.view.frame.size.width,
                                  bcv.view.frame.size.height);
      
      [self.scroller addSubview:bcv.view];
      
      NSArray *comps = [video componentsSeparatedByString:@":"];
      [bcv loadVideoWithID:[comps lastObject]];
      
      self.scroller.contentSize = CGSizeMake(self.scroller.contentSize.width,
                                             self.scroller.contentSize.height+bcv.view.frame.size.height);
      
    }
    
    
    
    count++;
  }
  
  NSLog(@"Scroller content height : %1.1f",self.scroller.contentSize.height);*/
  
}

#pragma mark - Google Ads
/*
- (void)adViewDidReceiveAd:(DFPBannerView *)adView {
  NSLog(@"Received ad successfully");
  
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
  NSLog(@"ERROR : %@",[error localizedDescription]);
}

- (void)adView:(DFPBannerView *)view willChangeAdSizeTo:(GADAdSize)size {
  NSLog(@"Changing ad size from %@ to %@",
        NSStringFromGADAdSize(view.adSize),
        NSStringFromGADAdSize(size));
}

- (void)adView:(DFPBannerView *)banner
didReceiveAppEvent:(NSString *)name
      withInfo:(NSString *)info {
  NSLog(@"Received app event (%@, %@)", name, info);
  // Checking for a "color" event name with information being a color.
  if ([name isEqualToString:@"color"]) {
    if ([info isEqualToString:@"red"]) {
      self.view.backgroundColor = [UIColor redColor];
    } else if ([info isEqualToString:@"green"]) {
      self.view.backgroundColor = [UIColor greenColor];
    } else if ([info isEqualToString:@"blue"]) {
      self.view.backgroundColor = [UIColor blueColor];
    }
  }
}*/

@end
