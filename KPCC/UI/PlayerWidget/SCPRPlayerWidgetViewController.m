//
//  SCPRPlayerWidgetViewController.m
//  KPCC
//
//  Created by Ben on 4/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRPlayerWidgetViewController.h"
#import "SCPRVolumeWidgetViewController.h"
#import "SCPRViewController.h"
#import "SCPRQueueCellViewController.h"
#import "SCPRSpinnerViewController.h"
#import "SCPRMasterRootViewController.h"
#import "global.h"


#define kSliderSquish 100.0

@interface SCPRPlayerWidgetViewController ()

@end

@implementation SCPRPlayerWidgetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



#pragma mark - UI/Controls
- (void)cleanoutSegment {
  [[AudioManager shared] fadeAudio:^{
    NSLog(@"Hit Callback...");
    self.queueViewController.currentPlayingDetails.text = @"";
    if ( [[AudioManager shared] streamingContentType] == StreamingContentTypeOnDemand ) {
      [[QueueManager shared] pop];
    }
  } hard:YES];
}

- (void)prime {
  [self orient];
  if ( ![[AudioManager shared] isPlayingAnyAudio] && [[AudioManager shared] streamingContentType] != StreamingContentTypeOnDemand ) {
    [[NetworkManager shared] fetchProgramInformationFor:[NSDate date]
                                              display:self];
  }
}

- (void)orient {

  /*
  self.bringUpQueueButton.frame = CGRectMake(self.view.frame.size.width-self.bringUpQueueButton.frame.size.width,
                                      self.bringUpQueueButton.frame.origin.y,
                                      self.bringUpQueueButton.frame.size.width,
                                      self.bringUpQueueButton.frame.size.height);
  
  
  [[DesignManager shared] avoidNeighbor:self.progressSlider
                               withView:self.timeElapsedLabel
                              direction:NeighborDirectionToLeft
                                padding:3.0];
  
  
  if ( [Utilities isIpad] ) {
    
    
    self.rightDividerView.center = CGPointMake(self.bringUpQueueButton.frame.origin.x-1.0, self.rightDividerView.center.y);
    [[DesignManager shared] avoidNeighbor:self.timeElapsedLabel
     withView:self.skipButton
                                direction:NeighborDirectionToLeft
                                  padding:-6.0];
  } else {
    self.rightDividerView.center = CGPointMake(self.bringUpQueueButton.frame.origin.x+15.0, self.rightDividerView.center.y);

  }
  
  [[DesignManager shared] alignVerticalCenterOf:self.timeElapsedLabel
                                       withView:self.progressSlider];*/
  
}

- (void)toggleProgramMode:(BOOL)on {
  self.programMode = on;
  
  if ( self.programMode ) {
    
    UIImageView *skipBackImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"skip_back.png"]];
    UIImageView *skipForwardImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"skip_fwd.png"]];
    

    
    self.skipBackButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, skipBackImage.frame.size.width,
                                                                     skipBackImage.frame.size.height)];
    
    self.skipForwardButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, skipForwardImage.frame.size.width,
                                                                        skipForwardImage.frame.size.height)];
    
    self.skipForwardButton.alpha = 0.0;
    self.skipBackButton.alpha = 0.0;
    
    [UIView animateWithDuration:0.22 animations:^{
      self.progressSlider.frame = CGRectMake(self.progressSlider.frame.origin.x+kSliderSquish,
                                             self.progressSlider.frame.origin.y,
                                             self.progressSlider.frame.size.width-kSliderSquish,
                                             self.progressSlider.frame.size.height);
      


      
      [[DesignManager shared] globalSetImageTo:@"skip_back.png"
                                     forButton:self.skipBackButton];
      [[DesignManager shared] globalSetImageTo:@"skip_fwd.png"
                                     forButton:self.skipForwardButton];
      

      
      self.actionButton.center = CGPointMake(self.actionButton.center.x+kSliderSquish/2.0,
                                             self.actionButton.center.y);
      
      [self.bottomFrame addSubview:self.skipBackButton];
      [self.bottomFrame addSubview:self.skipForwardButton];
      
      [[DesignManager shared] avoidNeighbor:self.actionButton
                                   withView:self.skipBackButton
                                  direction:NeighborDirectionToRight
                                    padding:5.0];
      
      [[DesignManager shared] avoidNeighbor:self.actionButton
                                   withView:self.skipForwardButton
                                  direction:NeighborDirectionToLeft
                                    padding:5.0];
      
      self.skipForwardButton.center = CGPointMake(self.skipForwardButton.center.x,
                                                  self.actionButton.center.y);
      
      self.skipBackButton.center = CGPointMake(self.skipBackButton.center.x,
                                                  self.actionButton.center.y);
      
    } completion:^(BOOL finished) {
      
      [self.skipBackButton addTarget:self
                              action:@selector(skipBackward:)
                    forControlEvents:UIControlEventTouchUpInside];
      
      [self.skipForwardButton addTarget:self
                                 action:@selector(skipForward:)
                       forControlEvents:UIControlEventTouchUpInside];
      
      [UIView animateWithDuration:0.22 animations:^{
        self.skipForwardButton.alpha = 1.0;
        self.skipBackButton.alpha = 1.0;
      }];
      
      
    }];
    
    
  } else {
    
    [UIView animateWithDuration:0.22 animations:^{
      self.skipForwardButton.alpha = 0.0;
      self.skipBackButton.alpha = 0.0;
      self.progressSlider.frame = self.originalScrubberFrame;
      self.actionButton.frame = self.originalPlayButtonFrame;
    } completion:^(BOOL finished) {
      [self.skipBackButton removeFromSuperview];
      [self.skipForwardButton removeFromSuperview];
      self.skipBackButton = nil;
      self.skipForwardButton = nil;
    }];
  }
  
}

- (void)hideVolumeSlider {
  UIView *volumeWidget = self.volumeWidget.view;
  if ( volumeWidget ) {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(volumeWidgetDisappeared)];
    volumeWidget.alpha = 0.0;
    [UIView commitAnimations];
  }
}

- (void)minimizeOrMaximize {
  if ( ![Utilities isIpad] ) {
    // Exit for now on non-iPad
    return;
  }
  
  if ( self.minimized ) {
    [self maximize];
  } else {
    [self minimize];
  }
  
}

- (void)minimize {
  
  if ( self.minimized ) {
    return;
  }

  
  SCPRViewController *parent = (SCPRViewController*)self.parentContainer;
  CGFloat adjustment = [[DesignManager shared] hasBeenInFullscreen] ? 20.0 : 0.0;
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.33];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(doneMinimizing)];
  self.queueViewController.minifiedQueueCountLabel.alpha = 1.0;
  CGRect r = CGRectMake(0.0,parent.view.frame.size.height-self.bottomFrame.frame.size.height-adjustment,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  self.view.frame = r;
  [UIView commitAnimations];
  
  

}

- (void)quietMinimize {
  if ( self.minimized && !self.forcePlacement ) {
    return;
  }
  
  if ( self.forcePlacement ) {
    self.forcePlacement = NO;
  }
  
  CGFloat tick = 0.0;
  if ( [Utilities isIOS7] ) {
    tick = 0.0;
  }
  
  SCPRViewController *parent = (SCPRViewController*)self.parentContainer;
  self.queueViewController.minifiedQueueCountLabel.alpha = 1.0;
  CGRect r = CGRectMake(0.0,parent.view.frame.size.height-self.bottomFrame.frame.size.height-tick,
                        self.view.frame.size.width,
                        self.view.frame.size.height);
  self.view.frame = r;
  self.minimized = YES;
  
}

- (void)maximize {
  
  if ( !self.minimized ) {
    return;
  }
  
  SCPRViewController *parent = (SCPRViewController*)self.parentContainer;
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.33];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(doneMaximizing)];
  self.queueViewController.minifiedQueueCountLabel.alpha = 0.0;
  self.view.frame = CGRectMake(0.0,parent.view.frame.size.height-self.view.frame.size.height,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  [UIView commitAnimations];

}

- (void)doneMinimizing {
  self.minimized = YES;
  self.view.alpha = 1.0;
}

- (void)doneMaximizing {
  self.minimized = NO;
}

- (void)adjustMinMaxButtonIcon {
  if ( self.minimized ) {
    [self.mixMaxUIButton setTitle:@"v" forState:UIControlStateNormal];
    [self.mixMaxUIButton setTitle:@"v" forState:UIControlStateHighlighted];
  } else {
    [self.mixMaxUIButton setTitle:@"^" forState:UIControlStateNormal];
    [self.mixMaxUIButton setTitle:@"^" forState:UIControlStateHighlighted];
  }
}

#pragma mark - Event Handling
- (void)skipForward:(id)sender {
  
}

- (void)skipBackward:(id)sender {
  
}

- (void)updateDetails {
  if ( ![[AudioManager shared] isPlayingAnyAudio] ) {
    if ( [[QueueManager shared] queueIsEmpty] ) {
      self.queueViewController.currentPlayingDetails.text = @"";
    }
  }
}

- (void)globalDismiss:(UITapGestureRecognizer*)tapper {
  [self hideVolumeSlider];
}

- (IBAction)sliderMoved:(UISlider *)slider {
  
  if ( [[AudioManager shared] streamPlaying] ) {
    //[[AudioManager shared] pauseStream];
  }
  
}

- (IBAction)buttonTapped:(id)sender {
  
  if ( self.actionButton == sender ) {
    [self playOrPauseStream:nil];
  }
  if ( self.volumeButton == sender ) {
    if ( self.volumeShowing ) {
      [self globalDismiss:nil];
    } else {
      self.volumeWidget = [[SCPRVolumeWidgetViewController alloc] initWithNibName:[[DesignManager shared] xibForPlatformWithName:@"SCPRVolumeWidgetViewController"] bundle:nil];
      CGPoint buttonCenter = self.volumeButton.center;
    
      if ( [Utilities isIpad] ) {

        self.volumePopup = [[UIPopoverController alloc] initWithContentViewController:self.volumeWidget];
      
        CGRect popoverRect = CGRectMake(buttonCenter.x - self.volumeWidget.view.frame.size.width/2.0,
                                    buttonCenter.y-self.volumeWidget.view.frame.size.height+250.0,
                                    self.volumeWidget.view.frame.size.width,
                                    self.volumeWidget.view.frame.size.height);
        CGSize popoverSize = CGSizeMake(self.volumeWidget.view.frame.size.width,
                                    self.volumeWidget.view.frame.size.height);
    
        self.volumePopup.popoverContentSize = popoverSize;
        [self.volumePopup presentPopoverFromRect:popoverRect
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionDown
                           animated:NO];
      } else {
      
        SCPRViewController *mainViewController = [[Utilities del] viewController];
      
        CGRect popoverRect = CGRectMake(buttonCenter.x - self.volumeWidget.view.frame.size.width/2.0,
                                      self.view.frame.origin.y-self.volumeWidget.view.frame.size.height/*-250.0*/,
                                      self.volumeWidget.view.frame.size.width,
                                      self.volumeWidget.view.frame.size.height);
        self.volumeWidget.view.frame = popoverRect;
        self.volumeWidget.view.tag = kVolumeWidgetTag;
      
        [[DesignManager shared] applyPerimeterShadowTo:self.volumeWidget.view];
        self.volumeWidget.view.alpha = 0.0;
        [mainViewController.view addSubview:self.volumeWidget.view];
      
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(volumeWidgetAppeared)];
        self.volumeWidget.view.alpha = 1.0;
        [UIView commitAnimations];
      
      }
    }
    
  }
  if ( self.bringUpQueueButton == sender ) {
    self.addedItemsCount = 0;
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root bringUpQueue];
  }
  if ( self.liveButton == sender ) {
    
    [[QueueManager shared] handleInterruption:self.progressSlider.value];
    [[QueueManager shared] liveStream];
    
    /*[[NSNotificationCenter defaultCenter] postNotificationName:@"changed_to_live_stream"
                                                        object:nil];*/
    
    /*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToLive)
                                                 name:@"spinner_appeared"
                                               object:nil];
    
    self.spinner = [[SCPRSpinnerViewController alloc]
                                          initWithNibName:[[DesignManager shared]
                                                           xibForPlatformWithName:@"SCPRSpinnerViewController"]
                                          bundle:nil];
    [self.spinner spinWithFinishedToken:@"live_stream_started"
                            inView:self.view];*/
    
  }
  if ( self.skipButton == sender ) {    
    [[QueueManager shared] pop];
  }
}



- (void)switchToLive {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"spinner_appeared"
                                                object:nil];
  
  [[QueueManager shared] handleInterruption:self.progressSlider.value];
  [[QueueManager shared] liveStream];
}

- (void)volumeWidgetAppeared {
  self.volumeShowing = YES;
  [[Utilities del] armGlobalDismiss:self];
}

- (void)volumeWidgetDisappeared {
  self.volumeShowing = NO;
  UIView *volumeWidget = self.volumeWidget.view;
  [volumeWidget removeFromSuperview];
  self.volumeWidget = nil;
  
  [[Utilities del] disarmGlobalDismiss];
}


- (IBAction)sliderTouched:(UISlider*)slider {
  self.scrubbing = YES;
  //[[AudioManager shared] disarmAudioParsingTimer];
}

- (IBAction)sliderReleased:(UISlider *)slider {
  [[AudioManager shared] seekStream:self.progressSlider.value];
  self.scrubbing = NO;
}



#pragma mark - AudioManagerDelegate
- (void)revealCurrentlyPlaying:(NSString *)title {
  [self.queueViewController.currentPlayingDetails titleizeText:title
                                                          bold:NO
   respectHeight:YES];
}

- (void)updateUIforAudioState {

  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    [[DesignManager shared] globalSetImageTo:@"pauseButton.png"
                                   forButton:self.actionButton];
  } else {
    [[DesignManager shared] globalSetImageTo:@"playButton.png"
                                   forButton:self.actionButton];
  }
}

- (void)handleLiveStream:(BOOL)live {
  if ( live ) {
    [[NetworkManager shared] fetchProgramInformationFor:[NSDate date]
                                                display:self];

    [[ScheduleManager shared] armScheduleUpdater];

    [self disableScrubber];
    
  } else {

    if ( [[AudioManager shared] streamingContentType] == StreamingContentTypeOnDemand ) {
      
      [self.queueViewController.currentPlayingDetails titleizeText:[[QueueManager shared].currentlyPlayingSegment name]
       bold:NO
       respectHeight:YES];
    }
    
    [[ScheduleManager shared] disarmScheduleUpdater];
    
    [self.listenLiveLabel setTextColor:[[DesignManager shared] darkoalColor]];

    [self enableScrubber];

  }
}

- (void)updateTimeText:(double)progress ofDuration:(double)duration {
  NSInteger rnd = (int)round(progress);
  NSString *pretty = [Utilities formalStringFromSeconds:rnd];
  [self.timeElapsedLabel titleizeText:pretty
                                 bold:NO];
}

- (void)updateScrubber:(double)progress {
  if ( !self.scrubbing ) {
    self.progressSlider.value = progress;
  }
}

- (void)disableScrubber {
  
  [UIView animateWithDuration:0.22 animations:^{
    
    self.onairSeat.alpha = 1.0;
    self.progressSlider.userInteractionEnabled = NO;
    self.progressSlider.alpha = 0.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"ghost.png"]
                              forState:UIControlStateNormal];
    
    self.skipButton.alpha = 0.0;
    self.skipLabel.alpha = 0.0;
    self.timeElapsedLabel.alpha = 0.0;
    
    [self.onairTopAnchor setConstant:19.0];
    [self.playerDetailsTopAnchor setConstant:17.0];
    [self.playerDetailsLeftAnchor setConstant:58.0];
    [self.bottomFrame layoutIfNeeded];

  }];

  
}

- (void)enableScrubber {
  
  if ( self.progressSlider.alpha == 1.0 ) {
    return;
  }
  
  [UIView animateWithDuration:0.22 animations:^{
    
    self.onairSeat.alpha = 0.0;
    self.timeElapsedLabel.alpha = 1.0;
    self.skipLabel.alpha = 1.0;
    self.skipButton.alpha = 1.0;
    self.progressSlider.userInteractionEnabled = YES;
    self.progressSlider.alpha = 1.0;
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"thumb_handle.png"]
                            forState:UIControlStateNormal];

    
    [self.queueViewController.currentPlayingDetails titleizeText:self.queueViewController.currentPlayingDetails.text
                                                            bold:NO
     respectHeight:YES];
    

    [self.playerDetailsTopAnchor setConstant:9.0];
    [self.playerDetailsLeftAnchor setConstant:9.0];
    [self.bottomFrame layoutIfNeeded];
    
    /*
    if ( ![Utilities isIpad] ) {
      self.queueViewController.currentPlayingDetails.frame = CGRectMake(self.queueViewController.currentPlayingDetails.frame.origin.x,
                                                                        8.0,
                                                                        self.queueViewController.currentPlayingDetails.frame.size.width,
                                                                        self.queueViewController.currentPlayingDetails.frame.size.height);
      
      [[DesignManager shared] alignLeftOf:self.queueViewController.currentPlayingDetails
                                 withView:self.progressSlider];
      
      [[DesignManager shared] avoidNeighbor:self.queueViewController.currentPlayingDetails
                                   withView:self.progressSlider
                                  direction:NeighborDirectionAbove
                                    padding:2.0];
      
      [[DesignManager shared] alignVerticalCenterOf:self.timeElapsedLabel
                                           withView:self.progressSlider];
      
      [[DesignManager shared] alignHorizontalCenterOf:self.skipButton
                                             withView:self.timeElapsedLabel];
     
    }*/
    
  }];
  
  
}

- (CGFloat)currentScrubberValue {
  return self.progressSlider.value;
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  
  if ( [content count] == 0 ) {
    return;
  }
  
  NSDictionary *program = [content objectAtIndex:0];
  self.queueViewController.currentPlayingDetails.alpha = 1.0;
  
  [self.queueViewController.currentPlayingDetails titleizeText:[program objectForKey:@"title"]
                                                          bold:YES];
  
  [[ContentManager shared] loadAudioMetaDataForAudio:[program objectForKey:@"title"]];
  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:[[ContentManager shared] audioMetaData]];
}

#pragma mark - Player
- (void)playOrPauseStream:(NSString *)url {

  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    
    // Cheat on the icon to eliminate appearance of delay
    /*[[DesignManager shared] globalSetImageTo:@"playButton.png"
                                   forButton:self.actionButton];*/
    
    
    [[AudioManager shared] pauseStream];

  } else {
    
    
    if ( [[AudioManager shared] paused] ) {
      [[AudioManager shared] unpauseStream];
    } else {
      if ( [[QueueManager shared] currentlyPlayingSegment] ) {
        if ( ![[QueueManager shared] queueIsEmpty] ) {
          if ( [[AudioManager shared] streamingContentType] != StreamingContentTypeLive ) {
            [[QueueManager shared] pop];
            [[ContentManager shared] saveContextOnMainThread];
            return;
          }
        }
      } else {
        // Go to Live Stream
        [[AudioManager shared] startStream:url];
        [[ContentManager shared] setSkipParse:YES];
        [[ContentManager shared] saveContextOnMainThread];
      }
    }
  }
}

- (void)overrideStream:(NSString *)url {
  [[AudioManager shared] setLastPlayedStreamURLString:nil];
  [[AudioManager shared] stopStream];
  [[AudioManager shared] startStream:url];
  [[[AudioManager shared] delegate] updateUIforAudioState];
}

- (void)setAddedItemsCount:(NSUInteger)addedItemsCount {
  _addedItemsCount = addedItemsCount;
  
  [self.addedItemsBadgeLabel titleizeText:[NSString stringWithFormat:@"%d",addedItemsCount]
                                   bold:YES];
  
  if ( [Utilities isIpad] ) {
    [UIView animateWithDuration:0.25 animations:^{
      if ( addedItemsCount == 0 ) {
        self.addedItemsBadgeLabel.alpha = 0.0;
        [self.bringUpQueueButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
      } else {
        [self.bringUpQueueButton setImageEdgeInsets:UIEdgeInsetsMake(0, -20.0, 0, 0)];
        self.addedItemsBadgeLabel.alpha = 1.0;
      }
    }];
  }
  
}

#pragma mark - Development
- (void)playLocalFile {
  NSString *localPath = [[NSBundle mainBundle]
                         pathForResource:@"localtest"
                         ofType:@"mp3"];
  
  [[AudioManager shared] startStream:localPath];
  
}

#pragma mark - View Controller lifecycle
- (void)viewDidAppear:(BOOL)animated {
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
  [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  // Stop receiving remote control events
  [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
  
  // Resign as first responder
  [self resignFirstResponder];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.addedItemsCount = 0;
  self.addedItemsBadgeLabel.backgroundColor = [[DesignManager shared] kingCrimsonColor];
  [self.addedItemsBadgeLabel titleizeText:@"" bold:YES];
  self.addedItemsBadgeLabel.layer.cornerRadius = self.addedItemsBadgeLabel.frame.size.height/2.0;
  self.addedItemsBadgeLabel.textColor = [UIColor whiteColor];
  
  [self.leftDividerView setVertical:YES];
  [self.rightDividerView setVertical:YES];
  self.leftDividerView.strokeColor = [[DesignManager shared] color:@[@221.0,@228.0,@229.0]];
  self.rightDividerView.strokeColor = [[DesignManager shared] color:@[@221.0,@228.0,@229.0]];
  self.originalScrubberFrame = self.progressSlider.frame;
  self.originalPlayButtonFrame = self.actionButton.frame;
  
  CGFloat alpha = 1.0;
  if ( [Utilities isIOS7] ) {
    alpha = 1.0;
  }
  
  if ( ![Utilities isIOS7] ) {
    if ( [Utilities isIpad] ) {
      [self.skipButton setImageEdgeInsets:UIEdgeInsetsMake(-22.0, 17.0, 0.0, 0.0)];
    }
  }
  
  if ( [Utilities isIpad] ) {
    [[DesignManager shared] globalSetTitleTo:@"SKIP"
                                   forButton:self.skipButton];
  } else {
    //self.skipButton.backgroundColor = [UIColor magentaColor];
  }

  
  self.onairSeat.backgroundColor = [[DesignManager shared] lightClayColor];
  [self.onairLabel titleizeText:@"ON AIR"
                           bold:NO];
  
  self.queueViewController.queueStatusLabel.text = @"";
  self.authorLabel.text = @"";
  self.teaserLabel.text = @"";
  self.progressSlider.userInteractionEnabled = NO;
  self.progressSlider.alpha = 0.5;
  self.progressSlider.value = 0.0;
  
  self.skipLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  [self.skipLabel titleizeText:@"SKIP"
                          bold:NO];
  
  self.timeElapsedLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  self.timeElapsedLabel.text = @"";
  
  [self disableScrubber];

  
  if ( [Utilities isIpad] ) {
    self.view.clipsToBounds = YES;
  } else {
    [self.bringUpQueueButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 14.0, 0.0, 0.0)];
    [self.actionButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 12.0)];
  }
  
  if ( ![Utilities isIOS7] ) {
    self.view.backgroundColor = [[DesignManager shared] frostedWindowColor:alpha];
    self.bottomFrame.backgroundColor = [UIColor whiteColor];
    self.topLine.strokeColor = [[DesignManager shared] color:@[@190.0,@196.0,@197.0]];
  } else {
#ifdef USE_FAKE_TRANSLUCENCE
    /*self.queueViewController.view.backgroundColor = [[DesignManager shared] frostedWindowColor:alpha];
    self.queueViewController.queueFormatControlView.backgroundColor = [[DesignManager shared] frostedWindowColor:alpha];*/
    
    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bottomFrame.frame.size.width,
                                                                self.bottomFrame.frame.size.height)];
    [self.bottomFrame addSubview:tb];
    [self.bottomFrame sendSubviewToBack:tb];
    
    UIToolbar *tb2 = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.queueViewController.queueFormatControlView.frame.size.width,
                                                                self.queueViewController.queueFormatControlView.frame.size.height)];
    
    [self.queueViewController.queueFormatControlView addSubview:tb2];
    [self.queueViewController.queueFormatControlView sendSubviewToBack:tb2];
    
    UIToolbar *tb3 = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.queueViewController.view.frame.size.width,
                                                                 self.queueViewController.view.frame.size.height)];
    
    [self.queueViewController.view addSubview:tb3];
    [self.queueViewController.view sendSubviewToBack:tb3];
    self.queueViewController.view.backgroundColor = [UIColor clearColor];
#else
    self.view.backgroundColor = [[DesignManager shared] frostedWindowColor:alpha];
    self.bottomFrame.backgroundColor = [UIColor whiteColor];
    self.topLine.strokeColor = [[DesignManager shared] color:@[@190.0,@196.0,@197.0]];
    
#endif
    
  
  }
  
  [[AudioManager shared] setDelegate:self];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared]
                                                turquoiseCrystalColor:1.0]
                                     forButton:self.skipButton];
  
  [self.view bringSubviewToFront:self.bottomFrame];
  
  self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
  [self.volumeView setShowsVolumeSlider:NO];
  //[self.volumeView sizeToFit];
  self.volumeView.alpha = 0.0;
  
  [self.view addSubview:self.volumeView];
  

  [self controlSwipers:YES];
  
  [self.progressSlider setMinimumTrackImage:[UIImage imageNamed:@"left_scrubber.png"]
                                   forState:UIControlStateNormal];
  
  [self.progressSlider setMinimumTrackImage:[UIImage imageNamed:@"left_scrubber.png"]
                                   forState:UIControlStateHighlighted];
  
  [self.progressSlider setMaximumTrackImage:[UIImage imageNamed:@"right_scrubber.png"]
                                   forState:UIControlStateNormal];
  
  [self.progressSlider setMaximumTrackImage:[UIImage imageNamed:@"right_scrubber.png"]
                                   forState:UIControlStateHighlighted];
  
  self.progressSlider.minimumValueImage = nil;
  self.progressSlider.maximumValueImage = nil;
  
  self.queueViewController.parent = self;
  
  [self.listenLiveLabel titleizeText:@"LISTEN LIVE"
                                bold:NO];
  
  [[DesignManager shared] globalSetImageTo:@"radio_tower.png"
                                 forButton:self.liveButton];
  
  [self.listenLiveLabel setTextColor:[[DesignManager shared] darkoalColor]];
  
  // Do any additional setup after loading the view from its nib.
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
  
  if (receivedEvent.type == UIEventTypeRemoteControl) {
    
    switch (receivedEvent.subtype) {
        
      case UIEventSubtypeRemoteControlPause:
      case UIEventSubtypeRemoteControlPlay:
      case UIEventSubtypeRemoteControlTogglePlayPause:
        [self playOrPauseStream:nil];
        break;
        
      case UIEventSubtypeRemoteControlPreviousTrack:
        break;
        
      case UIEventSubtypeRemoteControlNextTrack:
        if ( [[AudioManager shared] isPlayingOnDemand] ) {
          [[QueueManager shared] pop];
          break;
        }
      default:
        break;
    }
  }
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)controlSwipers:(BOOL)on {
  /*if ( on ) {
    self.swipeToMaximize = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(maximize)];
    self.swipeToMinimize = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(minimize)];
  
    self.swipeToMinimize.direction = UISwipeGestureRecognizerDirectionDown;
    self.swipeToMaximize.direction = UISwipeGestureRecognizerDirectionUp;
  
    [self.view addGestureRecognizer:self.swipeToMaximize];
    [self.view addGestureRecognizer:self.swipeToMinimize];
  } else {
    if ( self.swipeToMaximize ) {
      [self.view removeGestureRecognizer:self.swipeToMaximize];
      self.swipeToMaximize = nil;
    }
    if ( self.swipeToMinimize ) {
      [self.view removeGestureRecognizer:self.swipeToMinimize];
      self.swipeToMinimize = nil;
    }
  }*/
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
  
  
}

@end
