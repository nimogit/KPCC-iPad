//
//  SCPRQueueViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRQueueViewController.h"
#import "SCPRQueueCellViewController.h"
#import "SBJson.h"
#import "SCPRPlayerWidgetViewController.h"
#import "global.h"
#import "SCPRMasterRootViewController.h"

#define kDeleteButtonOffset 500000

@interface SCPRQueueViewController ()

@end

@implementation SCPRQueueViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  // Use NSTimer to update the Sleep Timer label every second. Invalidate if it is already running.
  if (self.sleepTimerLabelUpdateTimer) {
    [self. sleepTimerLabelUpdateTimer invalidate];
  }
  self.sleepTimerLabelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateSleepTimeLeft) userInfo:nil repeats: YES];
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if (self.sleepTimerLabelUpdateTimer) {
    [self.sleepTimerLabelUpdateTimer invalidate];
    self.sleepTimerLabelUpdateTimer = nil;
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(primeQueueForState)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
  
  [[QueueManager shared] setDelegate:self];
  
  if ( [Utilities isIOS7] ) {
    [self setNeedsStatusBarAppearanceUpdate];
  }
  
  [[QueueManager shared] setDelegate:self];
  
  NSString *text = [Utilities isIpad] ? @"SWITCH TO LIVE STREAM" : @"GO TO LIVE";
  [self.switchToLiveLabel titleizeText:text
                                  bold:NO
                         respectHeight:NO
                               lighten:YES];
  
  self.switchToLiveLabel.textColor = [[DesignManager shared] periwinkleColor];
  
  // Init controller and label settings for the sleep timer.
  self.sleepTimerTableViewController = [[SCPRSleepTimerTableViewController alloc] init];
  [self.sleepTimerLabel titleizeText:@"SLEEP TIMER"
                                  bold:NO
                         respectHeight:NO
                               lighten:YES];
  self.sleepTimerLabel.textColor = [[DesignManager shared] periwinkleColor];
  self.sleepTimerClockLabel.font = [[DesignManager shared] latoLight:self.sleepTimerClockLabel.font.pointSize];
  self.sleepTimerCancelLabel.font = [[DesignManager shared] latoLight:self.sleepTimerCancelLabel.font.pointSize];

  self.queueSlidableGrayLineView.padding = 20.0;
  
  self.queueBottomGrayLineView.strokeColor = [[DesignManager shared] silverliningColor];
  self.playPauseSpinner.color = [[DesignManager shared] periwinkleColor];
  self.queueFormatControlView.clipsToBounds = NO;
  self.topSeatView.backgroundColor = [UIColor whiteColor];
  self.controlSeatView.backgroundColor = [UIColor whiteColor];
  
  self.currentlyPlayingSeat.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  self.currentlyPlayingSeat.layer.borderWidth = 1.0;
  
  [self.leftVerticalDivider setVertical:YES];
  [self.rightVerticalDivider setVertical:YES];
  [self.sleepTimerVerticalDivider setVertical:YES];
  
  
  self.formatScroller.contentSize = CGSizeMake(self.formatScroller.frame.size.width*2,self.formatScroller.frame.size.height);
  self.view.frame = CGRectMake(0.0,
                               self.view.frame.origin.y,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  
  self.dummyQCV = [[SCPRQueueCellViewController alloc] initWithNibName:[[DesignManager shared]
                                                                        xibForPlatformWithName:@"SCPRQueueCellViewController"]
                                                                                     bundle:nil];
  self.myQueueLabel.textColor = [[DesignManager shared] periwinkleColor];
  [self.myQueueLabel titleizeText:@"MY QUEUE"
                             bold:NO
   respectHeight:NO
   lighten:NO];
  
  self.formatScroller.scrollEnabled = NO;
  
  CGFloat alpha = 1.0;
  if ( [Utilities isIOS7] ) {
    alpha = 0.5;
  }
  
  [self.nowPlayingLabel titleizeText:@"NOW PLAYING"
                                bold:NO
   respectHeight:NO
   lighten:NO];
  
  self.nowPlayingLabel.textColor = [[DesignManager shared] periwinkleColor];
  
  self.storyCountLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  self.maskView.layer.cornerRadius = 3.0;
  self.queueVisualContent = [[NSMutableArray alloc] init];
  self.currentPlayingDetails.textColor = [[DesignManager shared] deepOnyxColor];
  self.view.backgroundColor = [[DesignManager shared] frostedWindowColor:1.0];
  self.containerHeadView.backgroundColor = [[DesignManager shared] frostedWindowColor:1.0];
  self.queueTable.delegate = self;
  self.queueTable.dataSource = self;
  self.playPauseSpinner.alpha = 0.0;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(popRemote:)
                                               name:@"pop_queue"
                                             object:nil];
  

  
  [[DesignManager shared] alignVerticalCenterOf:self.queueTitleLabel
                                       withView:self.editButton];
  
  [self handleEditMode];
  [self buildQueue];
  
  
  [self selectMyQueue];
  [self primeQueueForState];
  [self primeButtonsForState];
  [self prime];
  
  self.confirmedDeletions = [[NSMutableDictionary alloc] init];
  
  NSString *queueSize = [NSString stringWithFormat:@"%d",(int)[self.queueContent count]];
  [[AnalyticsManager shared] logEvent: @"queue_accessed" withParameters:@{@"num_items_queued" : queueSize}];
}

- (void)prime {
  self.editing = NO;
  [self handleEditMode];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleDefault;
}


#pragma mark - UI
- (IBAction)formatSelected:(id)sender {

}

- (void)primeQueueForState {
  
  CGFloat stateAlpha = 0.0;
  CGFloat sleepTimerInitialStateAlpha = 0.0;
  CGFloat sleepTimerAlreadyActiveState = 0.0;
  if ( ![[QueueManager shared] currentlyPlayingSegment] ) {
    
    if ([[AlarmManager shared] isSleepTimerActive]) {
      sleepTimerInitialStateAlpha = 0.0;
      sleepTimerAlreadyActiveState = 1.0;
      [self updateSleepTimeLeft];
    } else {
      sleepTimerInitialStateAlpha = 1.0;
      sleepTimerAlreadyActiveState = 0.0;
    }
    
    [[NetworkManager shared] fetchProgramInformationFor:[NSDate date]
                                                display:self];
  } else {

    stateAlpha = 1.0;

    Segment *s = [[QueueManager shared] currentlyPlayingSegment];
    [self.currentPlayingDetails titleizeText:s.name
                                        bold:NO
                               respectHeight:YES];
    
  }
  
  [UIView animateWithDuration:0.22 animations:^{
    self.rightVerticalDivider.alpha = stateAlpha;
    self.switchToLiveButton.alpha = stateAlpha;
    self.switchToLiveLabel.alpha = stateAlpha;
    self.switchToLiveImage.alpha = stateAlpha;
    self.sleepTimerInactiveView.alpha = sleepTimerInitialStateAlpha;
    self.sleepTimerActiveView.alpha = sleepTimerAlreadyActiveState;
  }];
  
  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    [[DesignManager shared] globalSetImageTo:@"pauseButton.png"
                                   forButton:self.actionButton];
  } else {
    [[DesignManager shared] globalSetImageTo:@"playButton.png"
                                   forButton:self.actionButton];
  }
  
  NSInteger totalQueueSeconds = 0;
  
  
  for ( unsigned i = 0; i < [self.queueContent count]; i++ ) {
    Segment *s = [self.queueContent objectAtIndex:i];
    totalQueueSeconds += [s.duration intValue];
  }

  NSString *countStr = [NSString stringWithFormat:@"%d",[self.queueContent count]];
  if ( [self.queueContent count] == 0 ) {
    countStr = @"No";
  }
  NSString *noun = [self.queueContent count] == 1 ? @"story" : @"stories";
  
  NSString *runningTime = [Utilities prettyStringFromSeconds:totalQueueSeconds];
  NSString *base = [NSString stringWithFormat:@"%@ %@",countStr,noun];
  NSString *minified = [NSString stringWithFormat:@"Queue : %@",base];
  [self.minifiedQueueCountLabel snapText:minified bold:NO];
  if ( [self.queueContent count] > 0 ) {
    if ( [Utilities isIpad] ) {
      [self.storyCountLabel titleizeText:[NSString stringWithFormat:@"%@ (Total Time : %@)",base,runningTime]
                                    bold:NO];
    } else {
      [self.storyCountLabel titleizeText:[NSString stringWithFormat:@"%@ (%@)",base,runningTime]
                                    bold:NO];
    }
  } else {
    [self.storyCountLabel titleizeText:base bold:NO];
  }
  
  [self.addFiveButton.titleLabel titleizeText:self.addFiveButton.titleLabel.text
                                         bold:NO];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] burnedCharcoalColor]
                                     forButton:self.addFiveButton];
  
  //if ( !self.lockFromGhosting ) {
    if ( [self.queueContent count] == 0 ) {
      [UIView animateWithDuration:0.33 animations:^{
        self.emptyMsgSeat.alpha = 1.0;
        self.editing = NO;
        self.editButton.alpha = 0.0;
        
        SCPRPlayerWidgetViewController *player = [[Utilities del] globalPlayer];
        [player prime];
        
        [self handleEditMode];
      }];
    } else {
      [UIView animateWithDuration:0.33 animations:^{
        self.emptyMsgSeat.alpha = 0.0;
        self.editButton.alpha = 1.0;
      }];
    }
  //}
}

- (void)primeButtonsForState {
  
  [self.editButton.titleLabel titleizeText:self.editButton.titleLabel.text
                                      bold:NO];
  [self.removeAllButton.titleLabel titleizeText:self.removeAllButton.titleLabel.text
                                      bold:NO];
  [self.cancelButton.titleLabel titleizeText:self.cancelButton.titleLabel.text
                                      bold:NO];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] removeAllRedColor]
                                     forButton:self.removeAllButton];
  
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] cancelBlackColor]
                                     forButton:self.cancelButton];
  
  [[DesignManager shared] globalSetImageTo:@"icon-delete-queue.png"
                                 forButton:self.removeAllButton];
  
  [[DesignManager shared] globalSetImageTo:@"icon-cancel-queue.png"
                                 forButton:self.cancelButton];
  
  
  
  if ( [Utilities isIOS7] ) {
    [self.editButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
    [self.removeAllButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
    [self.cancelButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
  } else {
    [self.editButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
    [self.removeAllButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
    [self.cancelButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, -8.0, 0.0, 0.0)];
  }
  
  self.editButton.alpha = 0.0;
  
  [UIView animateWithDuration:0.33 animations:^{
    if ( self.editing ) {
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] periwinkleColor]
                                         forButton:self.editButton];
      

      [[DesignManager shared] globalSetImageTo:@"icon-save-queue.png"
                                     forButton:self.editButton];
      
      
      [[DesignManager shared] avoidNeighbor:self.removeAllButton
                                   withView:self.editButton
                                  direction:NeighborDirectionToRight
                                    padding:-10.0];
      

      
      self.cancelButton.alpha = 1.0;
      self.removeAllButton.alpha = 1.0;
      
    } else {
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] burnedCharcoalColor]
                                         forButton:self.editButton];
      
      
      [[DesignManager shared] globalSetImageTo:@"icon-edit-queue.png"
                                     forButton:self.editButton];

      
      self.editButton.frame = CGRectMake(self.controlSeatView.frame.size.width-self.editButton.frame.size.width-21.0,
                                         self.editButton.frame.origin.y,
                                         self.editButton.frame.size.width,
                                         self.editButton.frame.size.height);
      self.cancelButton.alpha = 0.0;
      self.removeAllButton.alpha = 0.0;
      
    }
  } completion:^(BOOL finished) {
    if ( self.editing ) {
      [[DesignManager shared] globalSetTitleTo:@"SAVE"
                                     forButton:self.editButton];
    } else {
      NSString *text = [Utilities isIpad] ? @"EDIT QUEUE" : @"EDIT";
      [[DesignManager shared] globalSetTitleTo:text
                                     forButton:self.editButton];
    }
    self.editButton.alpha = 1.0;
  }];

}

- (void)selectMyQueue {
  

  
}

- (void)selectLiveRewind {

}

- (void)setDirty:(BOOL)dirty {
  _dirty = dirty;
  
  if ( self.dirty ) {
    [[DesignManager shared] globalSetTitleTo:@"SAVE"
                                   forButton:self.editButton];
  }
  
}


- (void)exposeTopButton {
  
  if ( self.topShowing ) {
    return;
  }
  
  CGFloat shift = self.topButtonOriginalFrame.size.height*.47;
  
  [UIView animateWithDuration:0.25 animations:^{
    self.backToTopButton.center = CGPointMake(self.backToTopButton.center.x,
                                              self.backToTopButton.center.y+shift);
  } completion:^(BOOL finished) {
    [self topButtonExposed];
  }];

}

- (void)topButtonExposed {
  self.topShowing = YES;
}

- (void)hideTopButton {
  
  if ( !self.topShowing ) {
    return;
  }
  
  [UIView animateWithDuration:0.25 animations:^{
    self.backToTopButton.frame = self.topButtonOriginalFrame;
  } completion:^(BOOL finished) {
    [self topButtonHidden];
  }];
}

- (void)topButtonHidden {
  self.topShowing = NO;
}

#pragma mark - Button handling

- (IBAction)backToTopTapped:(id)sender {
  [self.queueTable setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
}

- (IBAction)emptyQueue:(id)sender {
  
  if ( [[AudioManager shared] isPlayingAnyAudio] &&
      [[AudioManager shared] streamingContentType] == StreamingContentTypeOnDemand ) {
    
      [[AudioManager shared] fadeAudio:^(void) {
        [[AudioManager shared] stopStream];
        [[AudioManager shared] setStreamingContentType:StreamingContentTypeLive];
        [[QueueManager shared] setCurrentlyPlayingSegment:nil];
        [self dropAllItemsFromQueue];
      
    } hard:YES];
  } else {
    [self dropAllItemsFromQueue];
  }
  
  self.dirty = NO;
  self.editing = NO;
  [self handleEditMode];
}

- (IBAction)deleteCommitted:(id)sender {
  UIButton *delete = (UIButton*)sender;
  NSInteger trueIndex = delete.tag-kDeleteButtonOffset;
  [self.confirmedDeletions removeObjectForKey:[NSString stringWithFormat:@"%d",trueIndex]];
  
  SCPRQueueCellViewController *cell = [self.queueVisualContent objectAtIndex:trueIndex];
  if ( [[QueueManager shared] articleIsPlayingNow:cell.relatedArticle] ) {
    if ( [[AudioManager shared] streamPlaying] ) {
      SCPRPlayerWidgetViewController *player = (SCPRPlayerWidgetViewController*)self.parent;
      [player cleanoutSegment];
    }
  }
  [[QueueManager shared] removeFromQueueLiteral:cell.relatedSegment];
  
  self.silentSquish = YES;
  
  [self buildQueue];

}

- (IBAction)deleteConfirmed:(id)sender {
  UIButton *b = (UIButton*)sender;
  NSString *key = [NSString stringWithFormat:@"%d",b.tag];
  if ( [self.confirmedDeletions objectForKey:key] ) {
    [self.confirmedDeletions removeObjectForKey:key];
    [UIView animateWithDuration:0.33 animations:^{
      b.transform = CGAffineTransformMakeRotation(0.0);
      SCPRQueueCellViewController *qvc = [self.queueVisualContent objectAtIndex:b.tag];
      [qvc suppressDeleteCommit];
    }];
  } else {
    [self.confirmedDeletions setObject:@1 forKey:key];
    [UIView animateWithDuration:0.33 animations:^{
      b.transform = CGAffineTransformMakeRotation([Utilities degreesToRadians:90.0]);
      SCPRQueueCellViewController *qvc = [self.queueVisualContent objectAtIndex:b.tag];
      [qvc revealDeleteCommit];
    }];
  }
  [self.queueTable reloadData];
}

- (IBAction)userWantsFive:(id)sender {
  
  [UIView animateWithDuration:0.55 animations:^{
    self.mouthImage.transform = CGAffineTransformMakeScale(1.0, -1.0);
    
  } completion:^(BOOL finished) {
    
    if ( self.nativeSpinner ) {
      [self.nativeSpinner removeFromSuperview];
    }
    self.nativeSpinner = [[UIActivityIndicatorView alloc]
                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.nativeSpinner.center = CGPointMake(self.containerHeadView.frame.size.width/2.0,
                                            self.containerHeadView.frame.size.height/2.0);
    [self.containerHeadView addSubview:self.nativeSpinner];
    self.nativeSpinner.alpha = 0.0;
    
    [UIView animateWithDuration:0.33 animations:^{
      self.emptyMsgSeat.alpha = 0.0;
      [self.nativeSpinner startAnimating];
      self.nativeSpinner.alpha = 1.0;
      
    } completion:^(BOOL finished) {
      self.mouthImage.transform = CGAffineTransformMakeScale(1.0, 1.0);
      
      self.waitingForFive = YES;
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(fivePicked)
                                                   name:@"five_picked"
                                                 object:nil];
      
      [self pickFive];
      


      
    }];
  }];
  
}

- (void)fivePicked {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"five_picked"
                                                object:nil];
  [UIView animateWithDuration:0.33 animations:^{
    self.nativeSpinner.alpha = 0.0;
  }];
}

- (IBAction)playOrPauseTapped:(id)sender {

  if ( [[AudioManager shared] paused] ) {
    [[AudioManager shared] unpauseStream];
  } else {
    
    if ( [[AudioManager shared] isPlayingAnyAudio] ) {
      [[AudioManager shared] pauseStream];
    } else {
      [UIView animateWithDuration:0.22 animations:^{
        self.actionButton.alpha = 0.0;
        [self.playPauseSpinner startAnimating];
        self.playPauseSpinner.alpha = 1.0;
      } completion:^(BOOL finished) {
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(hideSpinner)
         name:@"player_began_playing"
         object:nil];
        
        if ( [[QueueManager shared] currentlyPlayingSegment] ) {
          [self bootUpQueue:nil];
        } else {
          [self bootUpLiveStream];
        }
      }];
    }
  }
  
  [self primeQueueForState];

}


- (void)hideSpinner {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"player_began_playing"
                                                object:nil];
  
  [UIView animateWithDuration:0.22 animations:^{
    self.actionButton.alpha = 1.0;
    [self.playPauseSpinner startAnimating];
    self.playPauseSpinner.alpha = 0.0;
  }];
}

- (void)pickFive {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"spinner_appeared"
                                                object:nil];
  
  [[QueueManager shared] pluckFiveAndAddToQueue];
  
  [[AnalyticsManager shared] logEvent: @"queue_add_recent" withParameters:@{}];
}

- (void)playTapped:(id)sender {
  
  if ([[AlarmManager shared] isSleepTimerActive]) {
    [[AlarmManager shared] stopTimer];
  }
  
  UIButton *b = (UIButton*)sender;
  NSInteger tag = b.tag;
  Segment *s = [self.queueContent objectAtIndex:tag];
  
  [[QueueManager shared] playSpecificArticle:s];
  
}

- (IBAction)dismissTapped:(id)sender {
  [UIView animateWithDuration:0.55 animations:^{
    SCPRPlayerWidgetViewController *playa = [[Utilities del] globalPlayer];
    [playa.view setAlpha:1.0];
  }];
  
  [self dismissViewControllerAnimated:YES completion:^{
    
    SCPRMasterRootViewController *root = [[Utilities del] masterRootController];
    [root invalidateStatusBar];
    root.frozenOrientation = 0;
    
  }];
}

- (IBAction)switchToLiveTapped:(id)sender {
  [self bootUpLiveStream];
}

- (IBAction)sleepTimerTapped:(id)sender {
  self.sleepTimerModal = [[UIPopoverController alloc]
                     initWithContentViewController:self.sleepTimerTableViewController];
  
  self.sleepTimerModal.delegate = self;
  self.sleepTimerTableViewController.queueViewControllerDelegate = self;
  
  CGRect raw = self.sleepTimerButton.frame;
  CGRect cooked = [self.view convertRect:raw fromView:self.sleepTimerInactiveView];
  cooked = CGRectMake(cooked.origin.x, cooked.origin.y + 4, cooked.size.width, cooked.size.height);
  
  CGFloat s = [self.sleepTimerTableViewController.sleepTimerData count]*44.0;
  self.sleepTimerModal.popoverContentSize = CGSizeMake(self.sleepTimerTableViewController.tableView.frame.size.width,s);
  [self.sleepTimerModal presentPopoverFromRect:cooked
                                   inView:self.view
                 permittedArrowDirections:UIPopoverArrowDirectionUp
                                 animated:YES];
}

- (void) closeSleepTimerModal {
  if (self.sleepTimerModal) {
    [self.sleepTimerModal dismissPopoverAnimated:YES];
  }
}

- (IBAction)sleepTimerCancelTapped:(id)sender {
  [[AlarmManager shared] stopTimer];

  [UIView animateWithDuration:0.22 animations:^{
    self.sleepTimerActiveView.alpha = 0.0;
    self.sleepTimerInactiveView.alpha = 1.0;
  } completion:^(BOOL finished) {
    [self.sleepTimerClockLabel setText:@"00:00"];
  }];
}

- (void)updateSleepTimeLeft {

  if ([[AlarmManager shared] isSleepTimerActive]) {
    int secondsLeft = [[AlarmManager shared] secondsLeft];

    if (secondsLeft > 0) {
      int minutes, seconds;
      minutes = secondsLeft / 60;
      seconds = (secondsLeft % 3600) % 60;
      self.sleepTimerClockLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
  } else {
    if (self.sleepTimerActiveView.alpha == 1.0) {
      [UIView animateWithDuration:0.22 animations:^{
        self.sleepTimerActiveView.alpha = 0.0;
        self.sleepTimerInactiveView.alpha = 1.0;
      }];
    }
  }
}

- (void)dropAllItemsFromQueue {
  
  NSMutableArray *copy = [NSMutableArray arrayWithArray:self.queueContent];
  for ( Segment *s in copy ) {
    [[QueueManager shared] silentlyRemoveFromQueue:s];
  }
  [[ContentManager shared] saveContextOnMainThread];
  
  self.queueVisualContent = [[NSMutableArray alloc] init];
  self.queueContent = nil;
  [self.queueTable reloadData];
  [self primeQueueForState];
}

#pragma mark - ContentProcessor
- (void)handleProcessedContent:(NSArray *)content flags:(NSDictionary *)flags {
  
  if ( [content count] == 0 ) {
    return;
  }
  
  NSDictionary *program = [content objectAtIndex:0];
  self.currentPlayingDetails.alpha = 1.0;
  
  [self.currentPlayingDetails titleizeText:[program objectForKey:@"title"]
                                                          bold:YES];
  
  [[ContentManager shared] loadAudioMetaDataForAudio:[program objectForKey:@"title"]];
  
}

#pragma mark - Delegate
- (void)pop:(id)segment {
  Segment *s = (Segment*)segment;
  
  if ( ![self.queueContent containsObject:s] ) {
    NSLog(@"Segment not found in queue ... Weird");
  }
  [self.queueContent removeObject:s];
  if ( [self.queueContent count] > 0 ) {
    [self buildQueue];
    [[QueueManager shared] playSpecificArticle:[self.queueContent objectAtIndex:0]];
  } else {
    [self bootUpLiveStream];
  }
}

- (NSMutableArray*)representation {
  return [self queueContent];
}

- (void)queueAddedTo {
  

  [self buildQueue];
  
  if ( [self.queueContent count] > 0 ) {
    NSIndexPath *bottom = [NSIndexPath indexPathForRow:[self.queueVisualContent count]-1
                                             inSection:0];
    
    [self.queueTable scrollToRowAtIndexPath:bottom
                           atScrollPosition:UITableViewScrollPositionTop
                                   animated:YES];
  
  }

}

- (void)findAndPlayArticle:(Segment*)s {
  [self bootUpQueue:s];
}

- (void)queueRemovedFrom {
  
  [self primeQueueForState];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"notify_listeners_of_queue_change"
                                                      object:nil];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

}

#pragma mark - TableView
- (id)primeCell:(SCPRQueueCellViewController *)cell withIndex:(NSUInteger)index {
  
  if ( !cell ) {
    cell = [[SCPRQueueCellViewController alloc] initWithNibName:[[DesignManager shared]
                                                                 xibForPlatformWithName:@"SCPRQueueCellViewController"]
                                                                                    bundle:nil];
  }
  cell.view.frame = cell.view.frame;
  
  Segment *s = [self.queueContent objectAtIndex:index];
  s.queuePosition = [NSNumber numberWithInt:index];
  if ( !s ) {
    NSLog(@"Segment was nil here");
  }
  
  cell.relatedSegment = s;
  cell.parentContainer = self;
  [cell enableDoubleTap];
  
  cell.removeButton.alpha = 0.0;
  
  cell.view.tag = index;
  cell.relatedArticle = (NSDictionary*)[s.originalArticle JSONValue];
  cell.queueView.seatedImageView.alpha = 1.0;
  cell.queueView.parent = cell;
  

  
  cell.cellIndex = index;
  cell.deleteCommitButton.tag = index + kDeleteButtonOffset;
  cell.deleteConfirmButton.tag = index;
  cell.queueView.backgroundColor = [[DesignManager shared] frostedWindowColor:1.0];

  cell.playButton.tag = index;
  [cell.playButton addTarget:self
                      action:@selector(playTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  
  
  return cell;
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.queueContent count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  SCPRQueueCellViewController *qCtrl  = nil;
  SCPRQueueCellView *qCell = [self.queueTable dequeueReusableCellWithIdentifier:@"queue_cell"];
  if ( !qCell ) {
    qCtrl = [self primeCell:nil withIndex:indexPath.row];
    qCell = qCtrl.queueView;
  } else {
    NSLog(@"Found a QueueCell to reuse...");
    qCtrl = (SCPRQueueCellViewController*)qCell.parent;
    [self primeCell:qCtrl withIndex:indexPath.row];
  }
  qCell.selectionStyle = UITableViewCellSelectionStyleNone;
  return qCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  SCPRQueueCellView *qc = (SCPRQueueCellView*)cell;
  SCPRQueueCellViewController *qvc = (SCPRQueueCellViewController*)qc.parent;

  qvc.queueView.backgroundColor = [[DesignManager shared] frostedWindowColor:1.0];

  [qvc paint];
  
  qvc.queueView.seatedImageView.clipsToBounds = YES;
  
  if ( self.editing ) {
    qvc.timeLabel.alpha = 0.0;
  } else {
    qvc.timeLabel.alpha = 1.0;
  }
  
  if ( [Utilities isIOS7] ) {
#ifdef USE_FAKE_TRANSLUCENCE
    qvc.queueView.backgroundColor = [UIColor clearColor];
#endif
  }

  
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if ( indexPath.row == [self.queueContent count] ) {
    self.silentSquish = YES;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  return self.dummyQCV.view.frame.size.height;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  //SCPRQueueCellViewController *qvc = [self.queueVisualContent objectAtIndex:indexPath.row];
  return YES/*!qvc.immovable*/;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  id source = [self.theoreticalQueue objectAtIndex:sourceIndexPath.row];
  [self.theoreticalQueue removeObjectAtIndex:sourceIndexPath.row];
  [self.theoreticalQueue insertObject:source
                              atIndex:destinationIndexPath.row];
  
  
  if ( destinationIndexPath.row == 0 || sourceIndexPath.row == 0 ) {
    if ( [[AudioManager shared] streamPlaying] ) {
      self.playingItemChanging = YES;
      SCPRQueueCellViewController *qvc = [self.theoreticalQueue objectAtIndex:0];
      self.cellNewPlaying = qvc;
    }
  }
  
  self.dirty = YES;
  
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  [[QueueManager shared] removeFromQueueLiteral:[self.queueContent objectAtIndex:indexPath.row]];
  self.queueContent = nil;
  
  [self buildQueue];
}

#pragma mark - Queue operations
- (void)stampQueueOrderNumbers {
  for ( unsigned i = 0; i < [self.queueVisualContent count]; i++ ) {
    SCPRQueueCellViewController *qvc = [self.queueVisualContent objectAtIndex:i];
    qvc.queuePosition.text = [NSString stringWithFormat:@"%d",i+1];
    qvc.cellIndex = i;
  }                              
}

- (void)resume {
  
}

- (void)popRemote:(UITapGestureRecognizer*)note {

}

- (void)buildQueue {
 
  
  if ( !self.queueContent || [self.queueContent count] == 0 ) {
    self.queueContent = [[[ContentManager shared] orderedSegmentsForCollection:[[QueueManager shared] queue]] mutableCopy];
  }
  
  CATransition *transition = [CATransition animation];
  transition.type = kCATransitionFade;
  transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  transition.fillMode = kCAFillModeBoth;
  transition.duration = 0.12;
  transition.subtype = kCATransitionFromTop;
  transition.delegate = self;
  
  [[self.queueTable layer] addAnimation:transition
                                 forKey:@"UITableViewReloadDataAnimationKey"];
  
  [self.queueTable reloadData];
  
  [self primeQueueForState];
  
 
  
}



- (void)bootUpLiveStream {
  [[QueueManager shared] setCurrentlyPlayingSegment:nil];
  if ( !self.suspend ) {
    [[AudioManager shared] setStreamingContentType:StreamingContentTypeLive];
    [[AudioManager shared] setRebootStream:YES];
    [[AudioManager shared] startStream:kLiveStreamURL];
  }
  [self primeQueueForState];
}

- (void)bootUpQueue:(id)cell {
  
#ifndef STOCK_PLAYER
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(audioPlaybackStateCallback:)
   name:ASStatusChangedNotification
   object:nil];
#endif
  
  if ( !cell ) {
    cell = [self.queueContent objectAtIndex:0];
  }
  
  Segment *requested = (Segment*)cell;
  
  NSDictionary *requestedArticle = [requested.originalArticle JSONValue];
  
  
  NSString *title = [requestedArticle objectForKey:@"short_title"];
  if ( [Utilities pureNil:title] ) {
    title = [requestedArticle objectForKey:@"title"];
  }
  
  if ( ![Utilities pureNil:title] ) {
    self.currentPlayingDetails.alpha = 1.0;
    [self.currentPlayingDetails titleizeText:title
                                        bold:NO];
  }
  
  [[QueueManager shared] start:cell];
  
}

- (void)audioPlaybackStateCallback:(NSNotification*)note {
  
#ifndef STOCK_PLAYER
  if ( [AudioManager shared].audioStreamer.state == AS_STOPPING &&
      [AudioManager shared].audioStreamer.stopReason == AS_STOPPING_TEMPORARILY ) {
      self.openTrapForResume = YES;
      return;
  }
  
  
  if ( self.openTrapForStop ) {
    
    if ( [[AudioManager shared] isPlayingAnyAudio] ) {
      
      [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ASStatusChangedNotification
     object:nil];
    
      self.openTrapForResume = NO;
      self.openTrapForStop = NO;
    
      [[AudioManager shared] popSilence];
      [self.queueTable reloadData];
    }
    
    return;
    
  }
  
  if ( [[AudioManager shared] isPlayingAnyAudio] ) {
    
    if ( self.seeking ) {
      if ( !self.openTrapForStop ) {
        self.openTrapForStop = YES;
        
        SCPRQueueCellViewController *qvc = (SCPRQueueCellViewController*)[[QueueManager shared] currentlyPlayingSegment];
        [[AudioManager shared] seekStream:[qvc.relatedSegment.seekposition doubleValue]];
      }
    } else {
      
      [[NSNotificationCenter defaultCenter]
       removeObserver:self
       name:ASStatusChangedNotification
       object:nil];
      
      [[AudioManager shared] popSilence];
    }
  }
#endif
  
}

- (void)queueFinished {
  [self bootUpLiveStream];
}

- (BOOL)shouldAutorotate {
#ifdef SUPPORT_LANDSCAPE
  return YES;
#else
  return NO;
#endif
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [self closeSleepTimerModal];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

}

- (BOOL)shouldAutomaticallyForwardRotationMethods {
  return YES;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return YES;
}

#pragma mark - Edit Mode
- (IBAction)editQueue:(id)sender {
  self.editing = !self.editing;
  [self handleEditMode];
}

- (IBAction)cancelEdits:(id)sender {
  for ( unsigned i = 0; i < [self.queueVisualContent count]; i++ ) {
    SCPRQueueCellViewController *cell = [self.queueVisualContent objectAtIndex:i];
    cell.markedForDeletion = NO;
    [cell uncloak];
    
    cell.cellIndex = i;
    cell.queuePosition.text = [NSString stringWithFormat:@"%d",i+1];
  }
  
  self.dirty = NO;
  self.editing = NO;
  [self handleEditMode];
}

- (void)handleEditMode {
  
  
  [self primeButtonsForState];
  
  SCPRPlayerWidgetViewController *pw = (SCPRPlayerWidgetViewController*)self.parent;
  if ( self.editing ) {
    
    [pw controlSwipers:NO];
    self.theoreticalQueue = [NSMutableArray arrayWithArray:self.queueContent];
    
    [[AnalyticsManager shared] logEvent:@"queue_edit" withParameters:@{}];
  } else {
    
    [self.confirmedDeletions removeAllObjects];
    [pw controlSwipers:YES];

  }

  if ( self.dirty ) {
    self.queueContent = self.theoreticalQueue;
    [self buildQueue];
  }

  [self.queueTable setEditing:self.editing
                     animated:YES];
  
  [self.queueTable reloadData];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
