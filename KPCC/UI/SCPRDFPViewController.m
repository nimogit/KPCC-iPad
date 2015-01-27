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
  
#ifndef USE_LOCAL_ADS
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
  
  NSLog(@"Raw Ad HTML : %@",raw);
  
  NSString *cooked = [[FileManager shared] writeFileFromData:raw
                                                  toFilename:[NSString stringWithFormat:@"article_base_%d.html",(int)(random() % 398045)]];
  
  NSURL *url = [NSURL fileURLWithPath:cooked];
  self.adRequest = [NSURLRequest requestWithURL:url];
  [self.adView loadRequest:self.adRequest];
#else
  
  NSString *path = [[NSBundle mainBundle]
                    pathForResource:@"ad-placeholder"
                    ofType:@"html"];
  
  NSError *error = nil;
  NSString *raw = [[NSString alloc] initWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
  

  
  NSString *cooked = [[FileManager shared] writeFileFromData:raw
                                                  toFilename:[NSString stringWithFormat:@"article_base_%d.html",(int)(random() % 398045)]];
  
  NSURL *url = [NSURL fileURLWithPath:cooked];
  self.adRequest = [NSURLRequest requestWithURL:url];
  [self.adView loadRequest:self.adRequest];
  
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
#ifndef USE_LOCAL_ADS
  self.loadCount++;
  [self forceFinish];
#else
  self.loadCount = 4;
  [self forceFinish];
#endif
  
  
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

- (void)armSwipers {
  if ( self.rightSwiper ) {
    [self.view removeGestureRecognizer:self.rightSwiper];
    self.rightSwiper = nil;
  }
  self.rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(killSelf:)];
  self.rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
  
  if ( self.leftSwiper ) {
    [self.view removeGestureRecognizer:self.leftSwiper];
    self.leftSwiper = nil;
  }
  self.leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                               action:@selector(killSelf:)];
  self.leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
  
  if ( self.panner ) {
    [self.view removeGestureRecognizer:self.panner];
    self.panner = nil;
  }
  self.panner = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(killSelf:)];

  [self.view addGestureRecognizer:self.panner];
  [self.view addGestureRecognizer:self.leftSwiper];
  [self.view addGestureRecognizer:self.rightSwiper];
  
}

- (void)deactivationMethod {
  self.delegate = nil;
  [self.adView loadHTMLString:@""
                      baseURL:nil];
  self.okToDelete = YES;
}

- (void)killSelf:(UIGestureRecognizer*)gr {
  if ( gr == self.panner ) {
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer*)gr;
    CGPoint velocity = [pan velocityInView:self.view];
    if ( velocity.x > 0 ) {
      [self.delegate adWillDismiss:DismissDirectionRight];
    } else {
      [self.delegate adWillDismiss:DismissDirectionLeft];
    }
  }
  if ( gr == self.rightSwiper ) {
    [self.delegate adWillDismiss:DismissDirectionRight];
  }
  if ( gr == self.leftSwiper ) {
    [self.delegate adWillDismiss:DismissDirectionLeft];
  }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
