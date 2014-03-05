//
//  SCPRSpinnerViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRSpinnerViewController.h"
#import "global.h"

@interface SCPRSpinnerViewController ()

@end

@implementation SCPRSpinnerViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)spinWithFinishedToken:(NSString *)token inView:(UIView*)view {
  
  [self spinWithFinishedToken:token inView:view pushUp:NO];

  
}

- (void)spinWithFinishedToken:(NSString *)token inView:(UIView *)view pushUp:(BOOL)pushUp {
  
  NSString *image = self.blue ? @"spinner-blue.png" : @"spinning-donut.png";
  self.nativeSpinner.image = [UIImage imageNamed:image];
  
  [view addSubview:self.view];
  self.view.alpha = 0.0;
  
  CGFloat push = pushUp ? 62.0 : 0.0;
  
  self.view.center = CGPointMake(view.frame.size.width/2.0,
                                 view.frame.size.height/2.0-push);
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(quit)
                                               name:token
                                             object:nil];
  
  [UIView animateWithDuration:0.1 animations:^{
    self.view.alpha = 1.0;
  } completion:^(BOOL finished) {
   // dispatch_async(dispatch_get_main_queue(), ^{
#ifdef USE_WEB_SPINNER
      [self arm];
#else
      [self rotate];
#endif
  //  });
  }];

}

- (void)spinWithFinishedToken:(NSString *)token inView:(UIView *)view appeared:(SpinnerAppearedBlock)appeared {
  
  self.nativeSpinner.image = [UIImage imageNamed:@"spinning-donut.png"];
  
  [view addSubview:self.view];
  self.view.alpha = 0.0;
    
  self.view.center = CGPointMake(view.frame.size.width/2.0,
                                 view.frame.size.height/2.0);
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(quit)
                                               name:token
                                             object:nil];
  
  [UIView animateWithDuration:0.1 animations:^{
    self.view.alpha = 1.0;
  } completion:^(BOOL finished) {

    [self rotate:appeared];
    
  }];
  
}

- (void)spinInPlaceWithFinishedToken:(NSString *)token {
  
  self.inPlace = YES;
  
  NSString *image = self.blue ? @"spinner-blue.png" : @"spinning-donut.png";
  self.nativeSpinner.image = [UIImage imageNamed:image];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(quit)
                                               name:token
                                             object:nil];
  
  [UIView animateWithDuration:0.1 animations:^{
    self.view.alpha = 1.0;
  } completion:^(BOOL finished) {
   // dispatch_async(dispatch_get_main_queue(), ^{
#ifdef USE_WEB_SPINNER
      [self arm];
#else
    
      [self rotate];
    
#endif
   // });
  }];

}

- (void)arm {
  
  self.webSpinner.delegate = self;
  
  NSString *filename = self.view.frame.size.width == 26.0 ? @"spinning-donut.png" : @"spinning-donut@2x.png";
  
  [[FileManager shared] copyFromMainBundleToDocuments:filename
                                             destName:filename];
  
  NSString *s = [Utilities loadHtmlAsString:@"spinner"];
  s = [s stringByReplacingOccurrencesOfString:kWidthMacro
                                   withString:[NSString stringWithFormat:@"%d",(int)self.view.frame.size.width]];
  s = [s stringByReplacingOccurrencesOfString:kHeightMacro
                                   withString:[NSString stringWithFormat:@"%d",(int)self.view.frame.size.height]];
  
  if ( self.view.frame.size.width == 26.0 ) {
    s = [s stringByReplacingOccurrencesOfString:@"||_MARGIN_LEFT_||"
                                     withString:@"-8"];
    s = [s stringByReplacingOccurrencesOfString:@"||_MARGIN_TOP_||"
                                     withString:@"-8"];
  } else {
    s = [s stringByReplacingOccurrencesOfString:@"||_MARGIN_LEFT_||"
                                     withString:@"-8"];
    s = [s stringByReplacingOccurrencesOfString:@"||_MARGIN_TOP_||"
                                     withString:@"-8"];
  }
  
  s = [s stringByReplacingOccurrencesOfString:@"||_FILENAME_||"
                                   withString:filename];
  
  NSString *path = [[FileManager shared] writeContents:s
                                            toFilename:@"spinner_mod.html"];
  NSURL *file = [NSURL fileURLWithPath:path];
  
  [self.webSpinner loadRequest:[NSURLRequest requestWithURL:file]];
  
}

- (void)rotate:(SpinnerAppearedBlock)block {
  [UIView animateWithDuration:.125 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
    
    if ( self.currentAngle == 315.0 ) {
      self.currentAngle = 0.0;
    } else {
      self.currentAngle += 45.0;
    }
    
    
    self.nativeSpinner.transform = CGAffineTransformMakeRotation([Utilities degreesToRadians:self.currentAngle]);
    
  } completion:^(BOOL finished) {

    if ( self.stopRequested ) {
      self.stopRequested = NO;
      return;
    }
      
    if ( !self.firstTurnOccurred ) {
      self.firstTurnOccurred = YES;
      self.notificationFired = YES;
      dispatch_async(dispatch_get_main_queue(), block);
      
    }
      
    [self rotate:block];
      
  }];
}

- (void)rotate {
  

  
  [UIView animateWithDuration:.125 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
    
    if ( self.currentAngle == 315.0 ) {
      self.currentAngle = 0.0;
    } else {
      self.currentAngle += 45.0;
    }
    
    
    self.nativeSpinner.transform = CGAffineTransformMakeRotation([Utilities degreesToRadians:self.currentAngle]);
    
  } completion:^(BOOL finished) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ( self.stopRequested ) {
        self.stopRequested = NO;
        return;
      }
      
      if ( !self.firstTurnOccurred ) {
        self.firstTurnOccurred = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"spinner_appeared"
                                                            object:nil];
        self.notificationFired = YES;
        
      } 

      [self rotate];
      
    });
  }];
}

- (void)quit {

  @synchronized(self) {
    self.stopRequested = YES;
  }
  
  if ( self.spinTimer ) {
    if ( [self.spinTimer isValid] ) {
      [self.spinTimer invalidate];
    }
  }
  
  self.spinTimer = nil;
  
  
  [UIView animateWithDuration:.25 animations:^{
    self.view.alpha = 0.0;
    
  } completion:^(BOOL finished) {
    
    if ( !self.inPlace ) {
      [self.view removeFromSuperview];
    }
    [self notifyFinished];
  }];
}

- (void)notifyFinished {
  
  self.inPlace = NO;
  self.firstTurnOccurred = NO;
  self.notificationFired = NO;
  
  self.view.transform = CGAffineTransformMakeRotation(0.0);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"spinner_disappeared"
                                                      object:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [[NSNotificationCenter defaultCenter]
   postNotificationName:@"spinner_appeared"
   object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
