//
//  SCPRDFPViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 10/30/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRDFPViewController.h"
#import "SCPRMasterRootViewController.h"
#import "global.h"

@interface SCPRDFPViewController ()

@end

@implementation SCPRDFPViewController

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
  
  self.adView.alpha = 0.0;
  self.loadCount = 0;
  [self.spinner startAnimating];
  [self.adLoadingLabel titleizeText:self.adLoadingLabel.text
                               bold:NO];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)loadDFPAd {
  
  self.adView.delegate = self;
  self.adView.scrollView.scrollEnabled = NO;
  

  NSString *path = [[NSBundle mainBundle]
                    pathForResource:@"webdfp"
                    ofType:@"html"];
  
  NSError *error = nil;
  NSString *raw = [[NSString alloc] initWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
  
  CGFloat width = [Utilities isLandscape] ? 1024.0 : 768.0;
  CGFloat height = [Utilities isLandscape] ? 768.0 : 1024.0;
  
  raw = [raw stringByReplacingOccurrencesOfString:kWidthMacro
                                       withString:[NSString stringWithFormat:@"%d",(int)width]];
  raw = [raw stringByReplacingOccurrencesOfString:kHeightMacro
                                       withString:[NSString stringWithFormat:@"%d",(int)height]];
  raw = [raw stringByReplacingOccurrencesOfString:kAdVendorMacro
                                       withString:[[AnalyticsManager shared] adVendorID]];
  raw = [raw stringByReplacingOccurrencesOfString:kAdUnitMacro
                                       withString:[[AnalyticsManager shared] adUnitID]];
  raw = [raw stringByReplacingOccurrencesOfString:kAdGTPIdMacro
                                       withString:[[AnalyticsManager shared] adGtpID]];
  
  NSString *cooked = [[FileManager shared] writeFileFromData:raw
                                                  toFilename:[NSString stringWithFormat:@"article_base_%d.html",(int)(random() % 398045)]];
  
  NSURL *url = [NSURL fileURLWithPath:cooked];
  self.adRequest = [NSURLRequest requestWithURL:url];
  
#ifdef FAKE_AD_DELIVERY_FAILURE
  
  /*int rn = random() % 100;
  
  if ( rn < 85 ) {*/
    self.loadCount = 3;
    [self fail];
    return;
  //}
  
#else
  
  [self.adView loadRequest:[NSURLRequest requestWithURL:url]];

#endif
  
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  
  NSURL *url = [request URL];
  NSString *absolute = [url absoluteString];
  if ( [absolute rangeOfString:[[AnalyticsManager shared] urlHint]].location != NSNotFound ) {
    [[UIApplication sharedApplication] openURL:url];
    return NO;
  }
  
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  

  
  if ( !self.absoluteFinishTimer ) {
    self.absoluteFinishTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                                target:self
                                                              selector:@selector(forceFinish)
                                                              userInfo:nil
                                                               repeats:NO];
  }
  
  self.loadCount++;

}

- (void)forceFinish {
  
  self.absoluteFinishTimer = nil;
  
  if ( self.loadCount >= 3 ) {
    
    [UIView animateWithDuration:0.15 animations:^{
      self.adView.alpha = 1.0;
      self.spinner.alpha = 0.0;
      self.adLoadingLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
      
      [self.spinner stopAnimating];
      [self.delegate adDidFinishLoading];
      
      return;
    }];
    
  } else {
    if ( !self.failedOnce ) {
      self.loadCount = 0;
      self.failedOnce = YES;
      [self.adView loadRequest:self.adRequest];
      return;
    } else {
      [self fail];
      return;
    }
  }
  
}

- (void)fail {
  
  [self.adView stopLoading];
  [self.adLoadingLabel titleizeText:@"Ad Loading Failure."
                               bold:NO];
  [self.spinner stopAnimating];
  self.spinner.alpha = 0.0;
  
  [[ContentManager shared] setAdFailure:YES];
  
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  
  if ( self.loadCount >= 3 ) {
    [self fail];
  }
  
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
