//
//  SCPRPlayerWidgetViewController.h
//  KPCC
//
//  Created by Ben on 4/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SCPRQueueViewController.h"
#import "SCPRFlatShadedButton.h"
#import "SCPRSpinnerViewController.h"
#import "SCPRBadgeLabel.h"

@class SCPRVolumeWidgetViewController;

@interface SCPRPlayerWidgetViewController : UIViewController<AudioManagerDelegate,ContentProcessor> {
  UISlider *_progressSlider;
  UIButton *_actionButton;
  UIButton *_volumeButton;
  UIPopoverController *_volumePopup;
  UIView *_bottomFrame;
  UIButton *_liveButton;
  UIButton *_minMaxUIButton;
  UIButton *_minimizedPlayButton;
  UIButton *_showInfoButton;
  UIButton *_queueButton;
  
  CGRect _originalFrame;
  CGRect _originalPlayButtonFrame;
  
  BOOL _minimized;
  BOOL _scrubbing;
  BOOL _volumeShowing;
  
#ifdef DEBUG
  BOOL _breakOnHit;
#endif
  

}

- (IBAction)sliderMoved:(UISlider*)slider;
- (IBAction)sliderTouched:(UISlider*)slider;
- (IBAction)sliderReleased:(UISlider*)slider;
- (IBAction)buttonTapped:(id)sender;

- (void)updateDetails;
- (void)playLocalFile; // For DEVELOPMENT purposes only
- (void)playOrPauseStream:(NSString*)url;
- (void)overrideStream:(NSString*)url;
- (void)hideVolumeSlider;
- (void)orient;

// Minimizing / Maximizing
- (void)minimizeOrMaximize;
- (void)minimize;
- (void)quietMinimize;
- (void)maximize;
- (void)adjustMinMaxButtonIcon;
- (void)controlSwipers:(BOOL)on;
- (void)cleanoutSegment;
- (void)toggleProgramMode:(BOOL)on;
- (void)prime;

@property (nonatomic,strong) IBOutlet UISlider *progressSlider;
@property (nonatomic,strong) IBOutlet UIButton *actionButton;
@property (nonatomic,strong) IBOutlet UIButton *volumeButton;
@property (nonatomic,strong) UIPopoverController *volumePopup;
@property (nonatomic,strong) SCPRVolumeWidgetViewController *volumeWidget;
@property (nonatomic,weak) id parentContainer;
@property (nonatomic,strong) IBOutlet UIButton *liveButton;
@property (nonatomic,strong) IBOutlet UIButton *mixMaxUIButton;
@property (nonatomic,strong) IBOutlet UIView *bottomFrame;
@property (nonatomic,strong) IBOutlet UIButton *minimizedPlayButton;
@property (nonatomic,strong) IBOutlet UIButton *showInfoButton;
@property (nonatomic,strong) IBOutlet UIButton *queueButton;
@property (nonatomic,strong) IBOutlet UILabel *authorLabel;
@property (nonatomic,strong) IBOutlet UILabel *teaserLabel;
@property (nonatomic,strong) UIView *shadowView;
@property (nonatomic,strong) MPVolumeView *volumeView;
@property (nonatomic,strong) IBOutlet UIButton *skipButton;
@property (nonatomic,strong) IBOutlet UILabel *timeElapsedLabel;
@property (nonatomic,strong) IBOutlet UILabel *skipLabel;
@property (nonatomic,strong) IBOutlet UILabel *listenLiveLabel;
@property (nonatomic,strong) IBOutlet UIButton *bringUpQueueButton;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *leftDividerView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *rightDividerView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *topLine;
@property (nonatomic,strong) IBOutlet UIView *onairSeat;
@property (nonatomic,strong) IBOutlet UILabel *onairLabel;
@property (nonatomic,strong) IBOutlet SCPRBadgeLabel *addedItemsBadgeLabel;

@property (nonatomic,strong) UIButton *skipBackButton;
@property (nonatomic,strong) UIButton *skipForwardButton;

@property (nonatomic,strong) SCPRSpinnerViewController *spinner;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeToMinimize;
@property (nonatomic,strong) UISwipeGestureRecognizer *swipeToMaximize;
@property (nonatomic,strong) IBOutlet SCPRQueueViewController *queueViewController;

@property CGRect originalScrubberFrame;
@property CGFloat savedVolume;

@property CGRect originalFrame;
@property CGRect originalPlayButtonFrame;
@property BOOL scrubbing;
@property BOOL forcePlacement;

@property (nonatomic) NSUInteger addedItemsCount;

#ifdef DEBUG
@property BOOL breakOnHit;
#endif
@property BOOL minimized;
@property BOOL volumeShowing;
@property BOOL programMode;



@end
