//
//  SCPRTileViewController.m
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRTileViewController.h"
#import "global.h"
#import "SCPRSimpleNewsViewController.h"
#import "SCPRFlapViewController.h"

@interface SCPRTileViewController ()

@end

@implementation SCPRTileViewController

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
  self.view.clipsToBounds = NO;

  self.tileBody.layer.cornerRadius = 4.0;
  self.articleImage.layer.cornerRadius = 4.0;
  self.bannerBody.backgroundColor = [[DesignManager shared] obsidianColor:0.8];
  self.topicFrameView.backgroundColor = [[DesignManager shared] salmonColor:0.8];
  self.view.backgroundColor = [UIColor clearColor];
  self.cloakView.layer.cornerRadius = 4.0;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(queueStatus)
                                               name:@"notify_listeners_of_queue_change"
                                             object:nil];
  
	// Do any additional setup after loading the view.
}

- (UIImage*)renderSelf {
  CGRect oldFrame = self.view.frame;
  
  self.view.frame = CGRectMake(0.0,0.0,
                               self.view.frame.size.width,
                               self.view.frame.size.height);
  
  self.topicFrameView.alpha = 0.0;
  self.bannerBody.alpha = 0.0;
  CGFloat oldAlpha = self.view.alpha;
	self.view.alpha = 1;
	UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, 2.0);
	[self.view.layer.superlayer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
  //[self.view removeFromSuperview];
  
	self.view.alpha = oldAlpha;
	self.view.frame = oldFrame;
  self.topicFrameView.alpha = 1.0;
  self.bannerBody.alpha = 1.0;
	return resultingImage;
}

- (void)queueStatus {
  self.inQueue = [[QueueManager shared] articleIsInQueue:self.tileBody.relatedArticle];
  self.playingNow = [[QueueManager shared] articleIsPlayingNow:self.tileBody.relatedArticle];
  if ( self.inQueue || self.playingNow ) {
    self.inQueueView.alpha = 1.0;
    self.addOrRemoveStatusLabel.text = @"-";
  } else {
    self.inQueueView.alpha = 0.0;
    self.addOrRemoveStatusLabel.text = @"+";
  }
  
  if ( self.playingNow ) {
    self.inQueueTextLabel.text = @"Playing Now";
  } else {
    if ( self.inQueue ) {
      self.inQueueTextLabel.text = @"In Queue";
    }
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTileColor:(UIColor *)tileColor {
  _tileColor = tileColor;
  

  
}

- (void)unplug {
  
}

- (void)wireUpArticle:(NSDictionary *)article {
  
  self.article = article;
  
  if ( self.tap ) {
    [self.view removeGestureRecognizer:self.tap];
  }
  
  if ( self.fadeTimer ) {
    if ( [self.fadeTimer isValid] ) {
      [self.fadeTimer invalidate];
    }
    self.fadeTimer = nil;
  }
  
  self.tileBody.relatedArticle = article;
  [self.tileBody mergeWithArticle];
  
  CGFloat baseInterval = (CGFloat)(random() % 10)*1.0;
  baseInterval += 20.0;
  
  /*self.swiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(pluck)];
  if ( self.index % 2 == 0 ) {
    self.swiper.direction = UISwipeGestureRecognizerDirectionLeft;
  } else {
    self.swiper.direction = UISwipeGestureRecognizerDirectionRight;
  }*/
  
  self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                     action:@selector(handleTap)];
  
  [self.tap setNumberOfTapsRequired:1];
  
  /*self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(addToQueue)];
  [self.longPress setMinimumPressDuration:2.0];*/
  
  [self.view addGestureRecognizer:self.tap];
  //[self.view addGestureRecognizer:self.longPress];

  self.shadowView.alpha = 0.0;
  [self queueStatus];
  
  
  NSMutableArray *audio = [self.article objectForKey:@"audio"];
  if ( [Utilities pureNil:audio] ) {
    self.speakerButton.alpha = 0.0;
    self.addOrRemoveStatusLabel.alpha = 0.0;
  } else {
    self.speakerButton.alpha = 1.0;
    self.addOrRemoveStatusLabel.alpha = 1.0;
  }
  
 /* self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:baseInterval
                                                    target:self
                                                  selector:@selector(pluck)
                                                  userInfo:nil
                                                   repeats:NO];*/
}

- (void)setLeftSide:(BOOL)leftSide {
  _leftSide = leftSide;
  
  if ( leftSide ) {
    
    self.topicFrameView.frame = CGRectMake(0.0,self.topicFrameView.frame.origin.y,
                                           self.topicFrameView.frame.size.width,
                                           self.topicFrameView.frame.size.height);
    self.inQueueView.frame = CGRectMake(self.view.frame.size.width-self.inQueueView.frame.size.width,
                                        self.inQueueView.frame.origin.y,
                                        self.inQueueView.frame.size.width,
                                        self.inQueueView.frame.size.height);
    self.bannerBody.frame = CGRectMake(0.0,self.bannerBody.frame.origin.y,
                                       self.bannerBody.frame.size.width,
                                       self.bannerBody.frame.size.height);
    
    self.topicLabel.textAlignment = NSTextAlignmentLeft;
    self.tileBody.headLine.textAlignment = NSTextAlignmentLeft;
    self.tileBody.byLine.textAlignment = NSTextAlignmentLeft;
    self.tileBody.blurb1.textAlignment = NSTextAlignmentLeft;
    
    self.speakerButton.frame = CGRectMake(self.bannerBody.frame.size.width-self.speakerButton.frame.size.width-10.0,self.speakerButton.frame.origin.y,
                                          self.speakerButton.frame.size.width,
                                          self.speakerButton.frame.size.height);
  
  } else {
    self.topicFrameView.frame = CGRectMake(self.view.frame.size.width-self.topicFrameView.frame.size.width,self.topicFrameView.frame.origin.y,
                                           self.topicFrameView.frame.size.width,
                                           self.topicFrameView.frame.size.height);
    self.inQueueView.frame = CGRectMake(0.0,
                                        self.inQueueView.frame.origin.y,
                                        self.inQueueView.frame.size.width,
                                        self.inQueueView.frame.size.height);
    self.bannerBody.frame = CGRectMake(self.view.frame.size.width-self.bannerBody.frame.size.width,self.bannerBody.frame.origin.y,
                                       self.bannerBody.frame.size.width,
                                       self.bannerBody.frame.size.height);
    
    self.topicLabel.textAlignment = NSTextAlignmentRight;
    self.tileBody.headLine.textAlignment = NSTextAlignmentRight;
    self.tileBody.byLine.textAlignment = NSTextAlignmentRight;
    self.tileBody.blurb1.textAlignment = NSTextAlignmentRight;
    self.tileBody.headLine.frame = CGRectMake(self.tileBody.frame.size.width-self.tileBody.headLine.frame.size.width-20.0,self.tileBody.headLine.frame.origin.y,
                                              self.tileBody.headLine.frame.size.width,
                                              self.tileBody.headLine.frame.size.height);
    
    self.tileBody.byLine.frame = CGRectMake(self.tileBody.frame.size.width-self.tileBody.byLine.frame.size.width-20.0,self.tileBody.byLine.frame.origin.y,
                                              self.tileBody.byLine.frame.size.width,
                                              self.tileBody.byLine.frame.size.height);
    
    self.tileBody.blurb1.frame = CGRectMake(self.tileBody.frame.size.width-self.tileBody.blurb1.frame.size.width-20.0,self.tileBody.blurb1.frame.origin.y,
                                            self.tileBody.blurb1.frame.size.width,
                                            self.tileBody.blurb1.frame.size.height);
    
    self.speakerButton.frame = CGRectMake(10.0,self.speakerButton.frame.origin.y,
                                          self.speakerButton.frame.size.width,
                                          self.speakerButton.frame.size.height);
  }
  
  self.addOrRemoveStatusLabel.center = CGPointMake(self.speakerButton.center.x-6.0,self.speakerButton.center.y-1.0);
  
}

- (void)cloakWithDismissToken:(NSString *)token {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(uncloak:)
                                               name:token
                                             object:nil];
  
  
  [UIView animateWithDuration:0.22 animations:^{
    
    self.cloakView.alpha = 0.7;
    
  } completion:^(BOOL finished) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:@"tile_cloaked"
                                                          object:nil];
    });
        
  }];
  
}

- (void)uncloak:(NSNotification*)note {
  self.cloakView.alpha = 0.0;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:[note name]
                                                object:nil];
}

#pragma mark - Turnable
- (void)setObservableScroller:(UIScrollView *)observableScroller {
  if ( self.observableScroller && observableScroller != nil ) {
    return;
  }
  
  if ( _observableScroller && !observableScroller ) {
    [_observableScroller removeObserver:self
                             forKeyPath:@"contentOffset"];
  }
  
  _observableScroller = observableScroller;
  
  if ( observableScroller ) {
    [self.observableScroller addObserver:self
                              forKeyPath:@"contentOffset"
                                 options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                                 context:nil];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ( object == self.observableScroller ) {
    [[DesignManager shared] turn:self
                      withValues:change];
  }
}

- (SCPRFlapViewController*)leftFlap {
  return nil;
}

- (SCPRFlapViewController*)rightFlap {
  return nil;
}

- (UIView*)bendableView {
  return self.view;
}

- (void)handleTap {
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drill)
                                               name:@"tile_cloaked"
                                             object:nil];
  
  [self cloakWithDismissToken:@"single_article_ready"];

  
}

- (IBAction)addToQueueButtonTapped:(id)sender {
  if ( [[QueueManager shared] articleIsInQueue:self.article] ) {
    [[QueueManager shared] removeFromQueue:self.article];
  } else {
    [self addToQueue];
  }
  
  [self queueStatus];
}

- (void)drill {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"tile_cloaked"
                                                object:nil];
  
  SCPRSimpleNewsViewController *snc = (SCPRSimpleNewsViewController*)self.parentTileContainer;
  [snc handleDrillDown:self.article];
}

- (void)addToQueue {
  
  NSMutableArray *audio = [self.article objectForKey:@"audio"];
  if ( [Utilities pureNil:audio] ) {
    return;
  }
  

  
  self.lockOnce = YES;
  
  if ( [[QueueManager shared] articleIsInQueue:self.article] ) {
    [[QueueManager shared] removeFromQueue:self.article];

  } else {
  
    [[QueueManager shared] addToQueue:self.article
                              asset:nil];
  }
  
  [self queueStatus];
}

- (void)pluck {
  
  if ( self.fadeTimer ) {
    if ( [self.fadeTimer isValid] ) {
      [self.fadeTimer invalidate];
    }
    self.fadeTimer = nil;
  }
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:0.2];
  [UIView setAnimationDidStopSelector:@selector(tileFaded)];
  [UIView setAnimationDelegate:self];
  self.cloakView.alpha = 1.0;
  [UIView commitAnimations];
  
}

- (void)tileFaded {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"tile_disappearing"
                                                      object:[NSNumber numberWithInt:self.index]];
}

#ifdef LOG_DEALLOCATIONS
- (void)dealloc {
  
  NSLog(@"DEALLOCATING TILE VIEW CONTROLLER...");
  
}
#endif

@end
