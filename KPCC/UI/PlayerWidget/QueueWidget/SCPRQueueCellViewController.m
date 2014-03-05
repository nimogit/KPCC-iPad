//
//  SCPRQueueCellViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRQueueCellViewController.h"
#import "global.h"
#import "SCPRQueueViewController.h"

@interface SCPRQueueCellViewController ()

@end

@implementation SCPRQueueCellViewController

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
  
  self.originalImageFrame = self.imageSeatView.frame;
  self.originalTimeLabelFrame = self.timeLabel.frame;
  self.originalHeadlineFrame = self.headlineLabel.frame;
  self.originalCaptionFrame = self.captionLabel.frame;
  
  self.deleteCommitButton.frame = CGRectMake(self.view.frame.size.width-1.0,
                                             self.deleteCommitButton.frame.origin.y,
                                             self.deleteCommitButton.frame.size.width,
                                             self.deleteCommitButton.frame.size.height);
  
  self.originalCommiteButtonFrame = self.deleteCommitButton.frame;
  self.view.clipsToBounds = YES;
  //self.view.layer.cornerRadius = 3.0;
  self.playButtonView.alpha = 0.0;
  

  self.queueView = (SCPRQueueCellView*)self.view;
  self.queueView.parent = self;
  self.playingBannerLabel.alpha = 0.0;
  self.queueView.seatedImageView.clipsToBounds = YES;
  self.deleteCommitButton.special = YES;
  self.deleteCommitButton.shadeColor = [[DesignManager shared] removeAllRedColor];
  [self.deleteCommitButton prime];
  
  [self.deleteCommitButton.titleLabel titleizeText:self.deleteCommitButton.titleLabel.text
                                              bold:YES];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(monitorLocation:)
                                               name:@"locationChange"
                                             object:nil];
  
  [self.playingBannerLabel addObserver:self
                       forKeyPath:@"alpha"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
    // Do any additional setup after loading the view from its nib.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( [keyPath isEqualToString:@"alpha"] ) {
    self.queuePosition.alpha = 1.0-[[change objectForKey:@"new"] floatValue];
  }
}

- (void)enableDoubleTap {
  [self removeTappers];
  self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(playButtonTapped:)];
  self.doubleTap.numberOfTapsRequired = 2;
  [self.view addGestureRecognizer:self.doubleTap];
}

- (void)enableSingleTap {
  /*[self removeTappers];
  self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self.parentContainer
                                                           action:@selector(resume)];
  [self.view addGestureRecognizer:self.singleTap];*/
}

- (void)paint {
  Segment *s = self.relatedSegment;
  SCPRQueueCellViewController *cell = self;
  
  NSString *date = [NSDate stringFromDate:s.airdate
                               withFormat:@"MMM d, YYYY"];
  NSString *by = [cell.relatedArticle objectForKey:@"byline"];
  NSString *prettyByline = [NSString stringWithFormat:@"%@ | %@",date,by];
  
  NSInteger seconds = [s.duration intValue];
  if ( seconds == 0 ) {
    
    cell.queueView.timeLabel.alpha = 0.0;
    cell.queueView.timeLabel.text = @"";
    
  } else {
    
    [cell.queueView.timeLabel titleizeText:[Utilities formalStringFromSeconds:seconds]
                                      bold:NO];
    
  }
  

  
  [cell.queueView.headlineLabel titleizeText:[cell.relatedArticle objectForKey:@"short_title"]
                                        bold:NO
                               respectHeight:YES];
  
  [cell.queueView.captionLabel titleizeText:prettyByline
                                       bold:NO
                              respectHeight:YES];
  
  
  cell.queueView.timeLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  cell.queueView.headlineLabel.textColor = [[DesignManager shared] darkoalColor];
  cell.queueView.captionLabel.textColor = [[DesignManager shared] burnedCharcoalColor];
  
  CGFloat padding = [Utilities isIpad] ? 4.0 : 2.0;
  [[DesignManager shared] avoidNeighbor:cell.queueView.headlineLabel
                               withView:cell.queueView.captionLabel
                              direction:NeighborDirectionAbove
                                padding:padding];
  
  if ( [cell.relatedArticle objectForKey:@"local_image"] ) {
    [cell.queueView.seatedImageView loadLocalImage:[Utilities extractImageURLFromBlob:cell.relatedArticle
                                                                              quality:AssetQualityThumb]
                                           quietly:YES
                                        thumbscale:YES];
  } else {
    [cell.queueView.seatedImageView loadImage:[Utilities extractImageURLFromBlob:cell.relatedArticle
                                                                         quality:AssetQualityThumb]
                                      quietly:YES];
  }
  
  if ( ![Utilities isIpad] ) {
    [[DesignManager shared] alignVerticalCenterOf:cell.queueView.timeLabel
                                         withView:cell.queueView.captionLabel];
  }
  
  if ( [s isCurrentlyPlaying] ) {
    self.queueView.selected = YES;
  }
  
}

- (void)pause {
  
  self.paused = YES;
  //self.queueView.backgroundColor = [[DesignManager shared] queueCellIdleColor];
  
}

- (IBAction)playButtonTapped:(id)sender {
  [[QueueManager shared] playSpecificArticle:self.relatedArticle];
}

- (IBAction)removeButtonTapped:(id)sender {
  self.markedForDeletion = YES;
  self.removeButton.alpha = 0.0;
  [self cloakWithMessage:@"This article will be deleted"];
  [self.queueView setEditing:NO];
  
  SCPRQueueViewController *qvc = (SCPRQueueViewController*)self.parentContainer;
  qvc.dirty = YES;
}

- (void)unpause {
  
  self.paused = NO;
  
  /*SCPRQueueViewController *qvc = (SCPRQueueViewController*)self.parentContainer;
  [qvc.currentPlayingDetails titleizeText:self.relatedSegment.name bold:NO];
  
  //self.queueView.backgroundColor = [[DesignManager shared] queueCellPlayingColor];
  
  if ( ![[AudioManager shared] streamPlaying] ) {
    [qvc pop:nil play:YES];
  }*/
}

- (void)unhook {
  [self removeTappers];
  
}

- (void)monitorLocation:(NSNotification*)note {

}

- (void)cloakWithMessage:(NSString *)message {
  
  self.cloakView.frame = CGRectMake(0.0,0.0,self.view.frame.size.width,
                                    self.view.frame.size.height);
  self.cloakMessage.center = CGPointMake(self.cloakView.frame.size.width/2.0,
                                         self.cloakView.frame.size.height/2.0);
  
  [self.cloakMessage snapText:message bold:NO];
  
  [self.view addSubview:self.cloakView];
  
}

- (void)uncloak {
  if ( self.cloakView ) {
    [self.cloakView removeFromSuperview];
  }
}

- (void)removeTappers {
  if ( self.doubleTap ) {
    [self.view removeGestureRecognizer:self.doubleTap];
  }
  if ( self.singleTap ) {
    [self.view removeGestureRecognizer:self.singleTap];
  }
}

- (void)squish:(BOOL)animated {
  
  if ( self.squished ) {
    return;
  }
  
  if ( animated ) {
    [UIView animateWithDuration:0.33 animations:^{
      [[DesignManager shared] avoidNeighbor:self.deleteConfirmButton
                                 withView:self.imageSeatView
                                direction:NeighborDirectionToLeft
                                  padding:20.0];
    

    
      [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.headlineLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];
    

    
      [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.captionLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];
    
    

    
      [[DesignManager shared] avoidNeighbor:self.deleteCommitButton
                                 withView:self.timeLabel
                                direction:NeighborDirectionToRight
                                  padding:10.0];
    
      self.deleteConfirmButton.alpha = 1.0;
      self.timeLabel.alpha = 0.0;
    
    } completion:^(BOOL finished) {
      self.squished = YES;
    }];
  } else {
    
    self.squished = YES;
    [[DesignManager shared] avoidNeighbor:self.deleteConfirmButton
                                 withView:self.imageSeatView
                                direction:NeighborDirectionToLeft
                                  padding:20.0];
    
    
    
    [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.headlineLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];
    
    
    
    [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.captionLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];
    
    
    
    
    [[DesignManager shared] avoidNeighbor:self.deleteCommitButton
                                 withView:self.timeLabel
                                direction:NeighborDirectionToRight
                                  padding:10.0];
    
    self.deleteConfirmButton.alpha = 1.0;
    self.timeLabel.alpha = 0.0;
  }
  
}

- (void)unsquish {
  
  if ( !self.squished ) {
    return;
  }
  
  [UIView animateWithDuration:0.33 animations:^{
    self.imageSeatView.frame = self.originalImageFrame;
    self.timeLabel.frame = self.originalTimeLabelFrame;
    [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.headlineLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];
    [[DesignManager shared] avoidNeighbor:self.imageSeatView
                                 withView:self.queueView.captionLabel
                                direction:NeighborDirectionToLeft
                                  padding:10.0];

    
    
    self.deleteConfirmButton.alpha = 0.0;
    self.deleteCommitButton.alpha = 0.0;
    self.timeLabel.alpha = 1.0;
    self.deleteConfirmButton.transform = CGAffineTransformMakeRotation(0.0);
    
  } completion:^(BOOL finished) {
    self.squished = NO;
  }];
  
}

- (void)revealDeleteCommit {
  self.immovable = YES;
  self.queueView.editing = NO;
  [UIView animateWithDuration:0.33 animations:^{
    self.deleteCommitButton.alpha = 1.0;
    self.deleteCommitButton.frame = CGRectMake(self.view.frame.size.width-self.deleteCommitButton.frame.size.width-40.0,
                                               self.deleteCommitButton.frame.origin.y,
                                               self.deleteCommitButton.frame.size.width,
                                               self.deleteCommitButton.frame.size.height);
    [self.view bringSubviewToFront:self.deleteCommitButton];
  }];
}

- (void)suppressDeleteCommit {
  self.immovable = NO;
  self.queueView.editing = YES;
  [UIView animateWithDuration:0.33 animations:^{
    self.deleteCommitButton.alpha = 0.0;
    self.deleteCommitButton.frame = self.originalCommiteButtonFrame;
  }];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  NSLog(@"DEALLOCATING QUEUE CELL VIEW CONTROLLER");
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
