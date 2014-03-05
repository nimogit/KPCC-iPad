//
//  SCPRCompositeCellViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kWiderBannerPush 60.0

@interface SCPRCompositeCellViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIImageView *splashImage;
@property (nonatomic,strong) IBOutlet UIView *textSeatView;
@property (nonatomic,strong) IBOutlet UIView *topicBannerView;
@property (nonatomic,strong) IBOutlet UILabel *topicLabel;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UIImageView *gradientImage;
@property (nonatomic,strong) UITapGestureRecognizer *tapper;
@property (nonatomic,strong) IBOutlet UIImageView *circleGradient;
@property (nonatomic,weak) id parentCompositeNews;
@property (nonatomic,strong) id relatedArticle;

@property CGRect originalTopicSeatFrame;
@property CGRect originalTopicLabelFrame;
@property CGRect originalHeadlineLabelFrame;
@property BOOL locked;

- (void)focusArticle:(UITapGestureRecognizer*)tapper;
- (void)arm;

@end
