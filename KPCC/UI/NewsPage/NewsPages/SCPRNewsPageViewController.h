//
//  SCPRNewsPageViewController.h
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "UIImageView+ImageProcessor.h"
#import "SCPRViewController.h"
#import "SCPRGrayLineView.h"
#import "SCPRHBTView.h"

#define kClipBannerTag 389390

@interface SCPRNewsPageViewController : UIViewController<ContentContainer> {
  
  
}

- (void)activatePage;
- (void)deactivatePage;
- (void)arrange;
- (void)pad;
- (void)appendArticles:(NSArray*)articles;
- (void)reloadPage;

// Templates
- (void)templateBigTopSplitBottom:(NSInteger)index style:(NSUInteger)tempStyle;


@property (nonatomic,strong) IBOutlet UIImageView *image1;
@property (nonatomic,strong) IBOutlet UIImageView *image2;
@property (nonatomic,strong) IBOutlet UIImageView *image3;
@property (nonatomic,strong) IBOutlet UIImageView *image4;

@property (nonatomic,strong) IBOutlet UILabel *headline1;
@property (nonatomic,strong) IBOutlet UILabel *blurb1;
@property (nonatomic,strong) IBOutlet UILabel *byline1;
@property (nonatomic,strong) IBOutlet UILabel *headline2;
@property (nonatomic,strong) IBOutlet UILabel *blurb2;
@property (nonatomic,strong) IBOutlet UILabel *byline2;
@property (nonatomic,strong) IBOutlet UILabel *headline3;
@property (nonatomic,strong) IBOutlet UILabel *blurb3;
@property (nonatomic,strong) IBOutlet UILabel *byline3;
@property (nonatomic,strong) IBOutlet UILabel *headline4;
@property (nonatomic,strong) IBOutlet UILabel *blurb4;
@property (nonatomic,strong) IBOutlet UILabel *byline4;
@property (nonatomic,strong) IBOutlet UILabel *topicTitleLabel;

@property (nonatomic,strong) IBOutlet UIView *floatingSponsorView;
@property (nonatomic,strong) NSString *topicTitleCode;

@property (nonatomic,weak) UIScrollView *verticalContentScroller;
@property (nonatomic,weak) id parentContainer;
@property (nonatomic,weak) id<ContentProcessor> contentDelegate;
@property (nonatomic,weak) id pushed;

@property (nonatomic,strong) SCPRHBTView *topPart;
@property (nonatomic,strong) SCPRHBTView *split1;
@property (nonatomic,strong) SCPRHBTView *split2;


// Division
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayLine;
@property (nonatomic,strong) IBOutlet UIView *decorativeStripeView;

@property (nonatomic,strong) NSString *topicSlug;

@property NSInteger pageIndex;
@property NSInteger templateType;

@property BOOL activated;

@end
