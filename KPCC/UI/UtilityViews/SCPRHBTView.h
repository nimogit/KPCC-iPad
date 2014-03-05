//
//  SCPRHBTView.h
//  KPCC
//
//  Created by Ben Hochberg on 4/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"
#import "SCPRGrayLineView.h"
#import "SCPRViewController.h"

@interface SCPRHBTView : UIView<Arrangeable> {
  
}

@property (nonatomic,strong) NSDictionary *relatedArticle;
@property (nonatomic,strong) id<ContentContainer> navigator;
@property (nonatomic,strong) IBOutlet UIImageView *image1;
@property (nonatomic,strong) IBOutlet UILabel *headLine;
@property (nonatomic,strong) IBOutlet UILabel *byLine;
@property (nonatomic,strong) IBOutlet UILabel *blurb1;
@property (nonatomic,strong) IBOutlet UIView *bannerAdView;
@property (nonatomic,strong) IBOutlet UIView *matteView;
@property (nonatomic,strong) IBOutlet SCPRGrayLineView *grayDividerView;
@property (nonatomic,strong) IBOutlet UIButton *addToQueueButton;
@property (nonatomic,strong) IBOutlet UIButton *listenNowButton;
@property (nonatomic,strong) IBOutlet UILabel *dateLabel;
@property (nonatomic,strong) IBOutlet UIButton *drillDownButton;
@property (nonatomic,strong) IBOutlet UILabel *topicLabel;
@property (nonatomic,strong) IBOutlet UIView *topicFrameView;

@property (nonatomic,strong) IBOutlet UILabel *blurb2;
@property (nonatomic,strong) IBOutlet UILabel *blurb3;
@property (nonatomic,strong) IBOutlet UILabel *blurb4;
@property (nonatomic,strong) IBOutlet UIImageView *image2;
@property (nonatomic,strong) IBOutlet UIImageView *image3;
@property (nonatomic,weak) id parentContainer;

@property BOOL rightSide;
@property BOOL singleArticle;
@property BOOL snapshotContent;

// Arrangeable protocol
@property (nonatomic,strong) NSString *aspectCode;
@property NSUInteger templateStyle;
@property NSUInteger articleIndex;

- (void)makeTappable;
- (void)mergeWithArticle;
- (void)mergeWithArticle:(BOOL)blurry;
- (void)flush;


@end
