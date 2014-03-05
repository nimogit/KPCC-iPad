//
//  SCPRTileViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRHBTView.h"
#import "global.h"
#import "SCPRSpinnerViewController.h"

@interface SCPRTileViewController : UIViewController<Turnable>

@property (nonatomic,strong) IBOutlet SCPRHBTView *tileBody;
@property (nonatomic,strong) IBOutlet UIView *bannerBody;
@property (nonatomic,strong) IBOutlet UILabel *bannerText;
@property (nonatomic,strong) UIColor *tileColor;
@property (nonatomic,strong) IBOutlet UILabel *topicLabel;
@property (nonatomic,strong) IBOutlet UIView *topicFrameView;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) IBOutlet UIImageView *articleImage;
@property (nonatomic,strong) UISwipeGestureRecognizer *swiper;
@property (nonatomic,strong) UITapGestureRecognizer *tap;
@property (nonatomic,strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic,strong) IBOutlet UIView *inQueueView;
@property (nonatomic,strong) IBOutlet UILabel *inQueueTextLabel;
@property (nonatomic,strong) IBOutlet UIButton *speakerButton;
@property (nonatomic,strong) IBOutlet UILabel *addOrRemoveStatusLabel;
@property (nonatomic,strong) SCPRSpinnerViewController *spinner;
@property (nonatomic,weak) UIScrollView *observableScroller;

@property (nonatomic,strong) IBOutlet UIView *shadowView;

@property CGRect ghostFrame;
@property NSInteger ghostIndex;


@property NSInteger index;
@property (nonatomic) BOOL inQueue;
@property (nonatomic) BOOL playingNow;
@property (nonatomic) BOOL lockOnce;
@property (nonatomic) BOOL leftSide;

@property (nonatomic,strong) NSTimer *fadeTimer;
@property (nonatomic,weak) id parentTileContainer;
@property (nonatomic,strong) NSDictionary *article;

- (void)cloakWithDismissToken:(NSString*)token;
- (void)wireUpArticle:(NSDictionary*)article;
- (UIImage*)renderSelf;
- (IBAction)addToQueueButtonTapped:(id)sender;
@end
