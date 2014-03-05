//
//  SCPRQueueCellViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/7/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Segment.h"
#import "SCPRQueueCellView.h"
#import "SCPRFlatShadedButton.h"

@interface SCPRQueueCellViewController : UIViewController

@property BOOL paused;
@property BOOL editing;
@property BOOL markedForDeletion;
@property BOOL currentlyPlaying;
@property BOOL immovable;

@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (nonatomic,strong) NSDictionary *relatedArticle;
@property (nonatomic,weak) IBOutlet UILabel *queuePosition;
@property (nonatomic,weak) id parentContainer;

@property (nonatomic,strong) IBOutlet UIView *playButtonView;
@property (nonatomic,strong) IBOutlet UIImageView *playButtonImage;
@property (nonatomic,strong) IBOutlet UIButton *playButton;
@property (nonatomic,strong) Segment *relatedSegment;

@property (nonatomic,strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic,strong) UITapGestureRecognizer *singleTap;

@property (nonatomic,weak) SCPRQueueCellView *queueView;

@property (nonatomic,strong) IBOutlet UIView *imageSeatView;

@property (nonatomic,weak) IBOutlet UILabel *headlineLabel;
@property (nonatomic,weak) IBOutlet UILabel *captionLabel;
@property (nonatomic,weak) IBOutlet UILabel *timeLabel;
@property (nonatomic,weak) IBOutlet UILabel *playingBannerLabel;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) IBOutlet UILabel *cloakMessage;
@property (nonatomic,weak) IBOutlet UIButton *removeButton;

@property (nonatomic,strong) IBOutlet UIButton *deleteConfirmButton;
@property (nonatomic,strong) IBOutlet SCPRFlatShadedButton *deleteCommitButton;

@property CGRect originalImageFrame;
@property CGRect originalTimeLabelFrame;
@property CGRect originalCommiteButtonFrame;
@property CGRect originalHeadlineFrame;
@property CGRect originalCaptionFrame;

- (IBAction)playButtonTapped:(id)sender;
- (IBAction)removeButtonTapped:(id)sender;

- (void)enableSingleTap;
- (void)enableDoubleTap;
- (void)removeTappers;
- (void)pause;
- (void)unpause;
- (void)cloakWithMessage:(NSString*)message;
- (void)uncloak;
- (void)unhook;
- (void)revealDeleteCommit;
- (void)suppressDeleteCommit;
- (void)squish:(BOOL)animated;
- (void)unsquish;
- (void)paint;

@property BOOL squished;

@property NSUInteger cellIndex;

@end
