//
//  SCPRExternalWebContentViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRExternalWebContentViewController.h"
#import "global.h"
#import "SCPRTitlebarViewController.h"

@interface SCPRExternalWebContentViewController ()

@end

@implementation SCPRExternalWebContentViewController

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
  
  [[[Utilities del] globalTitleBar] eraseDonateButton];
  
  if ( ![Utilities isIOS7] ) {
    if ( !self.expectsRedirectURI ) {
      self.webContentView.center = CGPointMake(self.webContentView.center.x,
                                   self.webContentView.center.y+60.0);
      self.webContentView.frame = CGRectMake(self.webContentView.frame.origin.x,
                                             self.webContentView.frame.origin.y,
                                             self.webContentView.frame.size.width,
                                             self.webContentView.frame.size.height-60.0);
    }
  } else {
    if ( self.fromEditions ) {
      if ( [Utilities isLandscape] ) {
        self.webContentView.frame = CGRectMake(self.webContentView.frame.origin.x,
                                               self.webContentView.frame.origin.y,
                                               self.webContentView.frame.size.width,
                                               self.webContentView.frame.size.height+20.0);
      }
    }
  }
  
    // Do any additional setup after loading the view from its nib.
}

- (void)prime:(NSURLRequest*)request {
  self.webContentView.clipsToBounds = YES;
  self.cloakView.alpha = 0.0;
  self.webContentView.alpha = 0.0;
  [self.workingLabel titleizeText:self.workingLabel.text bold:YES];
  
  self.spinner.alpha = 1.0;
  [self.spinner startAnimating];
  
  self.webContentView.delegate = self;
  
  
  self.safariButton.shadeColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  self.readabilityButton.shadeColor = [[DesignManager shared] lavendarColor:1.0];
  
  self.request = request;
  
  //CGRect frm = self.webContentView.frame;
  
  if ( self.expectsRedirectURI ) {
    self.safariButton.alpha = 0.0;
    self.webContentView.scalesPageToFit = NO;
    //self.webContentView.scrollView.contentOffset = CGPointMake(-30.0,0.0);
  }
  
  [self.webContentView loadRequest:request];
}

- (void)deactivate {
  
}

- (void)buttonTapped:(id)sender {
  
  if ( sender == self.safariButton ) {
    NSURL *url = [self.request URL];
  
    [[UIApplication sharedApplication] openURL:url];
  }
  if ( sender == self.readabilityButton ) {
    [[NetworkManager shared] reduceArticle:[[self.request URL] absoluteString] processor:self];
  }
  if ( sender == self.bensOffbrandButton ) {
    if ( !self.reduced ) {
      [UIView animateWithDuration:0.28 animations:^{
        self.cloakView.alpha = 0.72;
      } completion:^(BOOL finished) {
        [[NetworkManager shared] reduceArticle:[[self.request URL] absoluteString] processor:self];
        //[[NetworkManager shared] remoteReductionForArticle:[[self.request URL] absoluteString] processor:self];
      }];
    } else {
      self.reduced = NO;
      [self prime:self.request];
    }
  }
}

#pragma mark - Backable
- (void)backTapped {
  
  [UIView animateWithDuration:0.1 animations:^{
    self.webContentView.alpha = 0.0;
  } completion:^(BOOL finished) {
    self.cleaningUp = YES;
    
    self.deactivationToken = [Utilities sha1:[self.request.URL path]];
    [[ContentManager shared] queueDeactivation:self];
    
    [self.webContentView stopLoading];
    
    NSString *blank = [[FileManager shared] copyFromMainBundleToDocuments:@"blank.html"
                                                                 destName:@"blank.html"];
    NSURL *url = [NSURL fileURLWithPath:blank];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLCacheStorageAllowed
                                                       timeoutInterval:10.0];
    [self.webContentView loadRequest:request];
  }];

}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  
}

- (void)handleReducedArticle:(NSDictionary *)reducedArticle {
  
  self.reducing = YES;
  NSString *content = [[FileManager shared] standardExternalContentForReducedArticle:reducedArticle];
  if ( [content rangeOfString:@"We're sorry but there was an error trying to prep this page for the best reading experience..."].location != NSNotFound ) {
    self.reducing = NO;
    [[[Utilities del] globalTitleBar] toggleReduced:NO];
    [UIView animateWithDuration:0.28 animations:^{
      self.cloakView.alpha = 0.0;
      
    } completion:^(BOOL finished) {
      [self.webContentView loadHTMLString:content baseURL:nil];
    }];
  } else {
    [self.webContentView loadHTMLString:content baseURL:nil];
  }
 
}


#pragma mark - UIWebView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if ( !self.expectsRedirectURI ) {
    return YES;
  } else {
    NSURL *url = [request URL];
    NSString *scheme = [url host];
    if ( [scheme rangeOfString:self.redirectPrefix].location != NSNotFound ) {
      [self.delegate requestURILoaded:[url absoluteString]];
      return NO;
    }
  }

  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  
  if ( self.cleaningUp ) {
    [self.webContentView removeFromSuperview];
    self.webContentView.delegate = nil;
    
    
    SCPRTitlebarViewController *tb = [[Utilities del] globalTitleBar];
    [tb pop];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    self.backContainer = nil;
    [[ContentManager shared] setUserIsViewingExpandedDetails:NO];
    [[ContentManager shared] popDeactivation:self.deactivationToken];
    
    if ( self.supplementalContainer ) {
      if ( [self.supplementalContainer respondsToSelector:@selector(contentFinishedDisplaying)] ) {
        [self.supplementalContainer contentFinishedDisplaying];
      }
    }
    
    return;
  }
  
  
  if ( self.expectsRedirectURI ) {
    self.webContentView.scrollView.maximumZoomScale = 1.0;
    self.webContentView.scrollView.minimumZoomScale = 0.75;
    self.webContentView.scrollView.zoomScale = 0.85;
    self.webContentView.backgroundColor = [[DesignManager shared] color:@[ @"221", @"221", @"221" ]];
    self.webContentView.scrollView.contentOffset = CGPointMake(-50.0,-20.0);
    self.view.center = CGPointMake(self.view.center.x,
                                   self.view.center.y-120.0);
  }
  
  [UIView animateWithDuration:0.2 animations:^{
    self.webContentView.alpha = 1.0;
    self.spinner.alpha = 0.0;
    self.view.alpha = 1.0;

  } completion:^(BOOL finished) {
    if ( self.reducing ) {
      self.reducing = NO;
      self.reduced = YES;
      
      [[[Utilities del] globalTitleBar] toggleReduced:YES];
      [UIView animateWithDuration:0.28 animations:^{
        self.cloakView.alpha = 0.0;
      }];
    } else {
      [[[Utilities del] globalTitleBar] toggleReduced:NO];
    }
  }];

  

}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@" ***** DEALLOCATING EXTERNAL WEB CONTENT ***** ");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
