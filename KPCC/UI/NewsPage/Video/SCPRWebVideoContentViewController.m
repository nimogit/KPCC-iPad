//
//  SCPRWebVideoContentViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 4/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRWebVideoContentViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "global.h"


#define CocoaJSHandler          @"scprvideo"

@interface SCPRWebVideoContentViewController ()

@end

@implementation SCPRWebVideoContentViewController

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
  
  self.dynamicWebContentView.delegate = self;
  self.dynamicWebContentView.scrollView.scrollEnabled = NO;
  
  self.jsHandler = [NSString stringWithContentsOfURL:[[NSBundle mainBundle]
                                                       URLForResource:@"ajax_handler"
                                                       withExtension:@"js"]
                                             encoding:NSUTF8StringEncoding
                                               error:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerWillExitFullscreen:)
                                               name:@"UIMoviePlayerControllerWillExitFullscreenNotification"
                                             object:nil];
  
    // Do any additional setup after loading the view from its nib.
}



- (void)loadContentURL:(NSURL *)address {
  NSURLRequest *request = [NSURLRequest requestWithURL:address];
  [self.dynamicWebContentView loadRequest:request];
}

- (void)loadContentString:(NSString *)string {
  NSArray *components = [string componentsSeparatedByString:@"/"];
  self.videoFile = [components lastObject];
  
  NSError *error = nil;
  NSString *s = [[NSString alloc] initWithContentsOfFile:string
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  NSURL *url = [NSURL fileURLWithPath:string];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  [self.dynamicWebContentView loadRequest:request];
  /*[self.dynamicWebContentView loadHTMLString:s
                                     baseURL:nil];*/
}

- (void)webViewDidStartLoad:(UIWebView *)webView {

}

- (void)playerWillExitFullscreen:(NSNotification*)note {
  int x = 1;
  x++;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSString *urlString = [[request URL] absoluteString];

  if ( [urlString rangeOfString:@"player.vimeo.com"].location != NSNotFound ) {
    self.requestURL = urlString;
  }
  
  //NSLog(@"urlString is %@",urlString);
  
  if ( [urlString rangeOfString:self.videoFile].location != NSNotFound ) {
    if ( !self.injected ) {
      self.injected = YES;
      
      return YES;
    }
  }
  if ([urlString rangeOfString:CocoaJSHandler].location != NSNotFound ) {
    
    // Extract the selector name from the URL
    NSArray *components = [urlString componentsSeparatedByString:@"://"];
    NSString *message = [components lastObject];
    NSLog(@"Message is %@",message);
    if ( [message isEqualToString:@"player_playing"] ) {
      if ( !self.firstPlaySent ) {
        self.firstPlaySent = YES;
        
        NSString *callback = [self.dynamicWebContentView stringByEvaluatingJavaScriptFromString:@"forcePlay();"];
        NSLog(@"Callback from forcePlay : %@",callback);
        
        [[AudioManager shared] fadeAudio:nil];
        return NO;
      }
      
      [[AudioManager shared] fadeAudio:nil];
      
    }
    if ( [message isEqualToString:@"ended"] ) {
      [self performSelectorOnMainThread:@selector(unlockAudioStream)
                             withObject:nil
                          waitUntilDone:NO];
    }

    return NO;
  }
  
  
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  NSString *urlString = [[webView.request URL] absoluteString];
  //NSLog(@"Request is : %@",urlString);
  
  if ( [self.requestURL rangeOfString:@"player.vimeo.com"].location != NSNotFound ) {
    if ( !self.videoLoaded ) {
      [NSTimer scheduledTimerWithTimeInterval:0.5
                                       target:self
                                     selector:@selector(prepVimeo)
                                     userInfo:nil
                                      repeats:NO];
      self.videoLoaded = YES;
    }
  }
}

- (void)prepVimeo {
  NSError *e = nil;
  /*NSString *s = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://a.vimeocdn.com/js/froogaloop2.min.js"]
                                               encoding:NSUTF8StringEncoding
                                                  error:&e];*/
  
  //NSString *ret = [self.dynamicWebContentView stringByEvaluatingJavaScriptFromString:@"prep();"];
  //NSLog(@"JS Returned : %@",ret);
  
  //[self.dynamicWebContentView stringByEvaluatingJavaScriptFromString:@"player.play();"];
  //[self.dynamicWebContentView stringByEvaluatingJavaScriptFromString:s];
}

- (void)unlockAudioStream {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"userFinishedWithVideo" object:nil];
}

- (void)snapFramesTo:(UIView *)view {
  self.view.frame = CGRectMake(0.0,0.0,view.frame.size.width,view.frame.size.height);
  //self.dynamicWebContentView.frame = CGRectMake(0.0,0.0,view.frame.size.width,view.frame.size.height);
}

- (void)fullScreen {

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
