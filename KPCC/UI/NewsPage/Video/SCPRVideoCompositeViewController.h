//
//  SCPRVideoCompositeViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/2/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>



#define kInitialCount 3

@interface SCPRVideoCompositeViewController : UIViewController<UIWebViewDelegate>

@property (nonatomic,strong) NSMutableArray *contentVector;
@property (nonatomic,strong) IBOutlet UIScrollView *scroller;
@property (nonatomic,strong) IBOutlet UIWebView *webBanner;
@property BOOL initialAdLoad;
@property NSInteger count;

- (void)loadVideoContent:(NSArray*)content;

@end
