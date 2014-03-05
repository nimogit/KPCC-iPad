//
//  SCPRNewsPageContainerController.h
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRGrayStripView.h"
#import "SCPRViewController.h"

@interface SCPRNewsPageContainerController : UIViewController<Turnable> {
  UIScrollView *_contentScroller;
}

@property (nonatomic,strong) IBOutlet UIScrollView *contentScroller;
@property (nonatomic,weak) UIScrollView *observableScroller;

@property (nonatomic,strong) id child;
@property (nonatomic,strong) UINavigationController *designatedNav;
@property (nonatomic,strong) NSString *topicSlug;
@property (nonatomic,strong) IBOutlet SCPRGrayStripView *grayStrip;
@property (nonatomic,strong) IBOutlet UIView *bannerAdView;
@property (nonatomic,strong) IBOutlet UILabel *pageTitleLabel;
@property (nonatomic,strong) NSMutableArray *newsPages;
@property (nonatomic,strong) NSMutableArray *totalContent;
@property (nonatomic,weak) id<ContentProcessor> contentDelegate;
@property NSInteger pageIndex;
@property NSInteger originalQuantity;

@property (nonatomic,strong) UIView *shadowView;

@property BOOL trashNavigation;
@property CGRect ghostFrame;

- (void)detach;
- (void)appendContent;

@end
