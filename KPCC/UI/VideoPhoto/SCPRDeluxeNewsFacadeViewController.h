//
//  SCPRDeluxeNewsFacadeViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRFloatingEmbedViewController.h"
#import "global.h"

@interface SCPRDeluxeNewsFacadeViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIImageView *splashImage;
@property (nonatomic,strong) IBOutlet UIView *bluePaddingView;
@property (nonatomic,strong) IBOutlet UIView *categorySeatView;
@property (nonatomic,strong) IBOutlet UILabel *slideshowLabel;
@property (nonatomic,strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic,strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic,strong) IBOutlet UILabel *headlineLabel;
@property (nonatomic,strong) IBOutlet UIView *socialCountView;
@property (nonatomic,strong) IBOutlet UIView *socialLineDivider;
@property (nonatomic,strong) IBOutlet UILabel *facebookCountLabel;
@property (nonatomic,strong) IBOutlet UIImageView *facebookLogoImage;
@property (nonatomic,strong) IBOutlet UILabel *twitterCountLabel;
@property (nonatomic,strong) IBOutlet UIImageView *twitterLogoImage;
@property (nonatomic,strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic,strong) IBOutlet UIView *cardView;
@property (nonatomic,strong) IBOutlet UIImageView *playOverlayImage;
@property (nonatomic,strong) NSDictionary *pvArticle;
@property (nonatomic,weak) id parentPVController;
@property (nonatomic,strong) UIButton *tapperButton;
@property (nonatomic,strong) NSString *category;
@property (nonatomic,strong) SCPRFloatingEmbedViewController *floatingVideoController;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (nonatomic,strong) IBOutlet UIWebView *formattedSummaryTextView;
@property (nonatomic,strong) IBOutlet UIView *grayLineDivider;
@property (nonatomic,strong) NSString *imgUrl;

@property BOOL embiggened;
@property BOOL noAsset;
@property BOOL verticalOrSquareAsset;
@property ScreenContentType contentType;

@property CGRect originalBlurbFrame;
@property CGRect originalHeadlineFrame;

- (void)mergeWithPVArticle:(NSDictionary*)pvArticle;
- (void)snapCategorySeat;
- (void)handleCategoryForPhotoVideo;
- (void)handleCategoryForComposite;
- (void)arm;

@end
