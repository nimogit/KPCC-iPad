//
//  SCPREditionAtomViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 7/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRGrayLineView.h"

@interface SCPREditionAtomViewController : UIViewController<ContentProcessor>

@property (nonatomic,strong) IBOutlet UIImageView *gradientImageView;
@property (nonatomic,strong) IBOutlet UIImageView *splashImageView;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UIButton *expandButton;
@property (nonatomic,strong) IBOutlet UIView *detailsSeatView;
@property (nonatomic,strong) IBOutlet UIView *coloredPortionOfBase;
@property (nonatomic,strong) NSDictionary *relatedArticle;
@property (nonatomic,strong) NSDictionary *nativeArticle;
@property (nonatomic,strong) id externalContent;
@property (nonatomic,strong) id internalContent;
@property (nonatomic,weak) id parentMolecule;
@property (nonatomic,strong) IBOutlet UIImageView *topGradient;
@property (nonatomic,strong) IBOutlet UIButton *captionButton;
@property (nonatomic,strong) IBOutlet UILabel *photoCaptionLabel;
@property (nonatomic,strong) IBOutlet UIView *photoCaptionSeat;
@property (nonatomic,strong) IBOutlet UIButton *altTriggerButton;
@property (nonatomic,strong) NSTimer *photoCaptionTimer;
@property (nonatomic,strong) UITapGestureRecognizer *captionTapper;
@property (nonatomic,strong) IBOutlet UIView *blueStripeView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *edgeDivider;
@property (nonatomic,strong) IBOutlet UIScrollView *iphoneScroller;
@property (nonatomic,strong) IBOutlet UIImageView *bottomGradient;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *cardHeightAnchor;
@property (nonatomic,strong) IBOutlet NSLayoutConstraint *bottomAnchor;
@property NSUInteger index;

@property BOOL trustedSource;
@property BOOL suppressCaption;
@property BOOL captionShowing;
@property BOOL detailsPushed;

- (void)mergeWithArticle;
- (IBAction)buttonTapped:(id)sender;
- (BOOL)isKPCCArticle;
- (void)fadePhotoCaption;
- (void)squash;

@end
