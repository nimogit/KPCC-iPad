//
//  SCPRCompositeCellViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCompositeCellViewController.h"
#import "SCPRCompositeNewsViewController.h"
#import "global.h"

@interface SCPRCompositeCellViewController ()

@end

@implementation SCPRCompositeCellViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
  self.originalTopicLabelFrame = self.topicLabel.frame;
  self.originalTopicSeatFrame = self.topicBannerView.frame;
  self.originalHeadlineLabelFrame = self.headlineLabel.frame;
  self.topicBannerView.backgroundColor = [[DesignManager shared] translucentPeriwinkleColor];
  
	// Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
  self.circleGradient.alpha = 0.0;
}

- (void)focusArticle:(UITapGestureRecognizer *)tapper {
  [UIView animateWithDuration:0.22 animations:^{
    self.circleGradient.alpha = 1.0;
  } completion:^(BOOL finished) {
    
    SCPRCompositeNewsViewController *news = (SCPRCompositeNewsViewController*)self.parentCompositeNews;
    [news focusArticle:self.relatedArticle];
    
  }];
}

- (void)arm {
  if ( self.tapper ) {
    [self.view removeGestureRecognizer:self.tapper];
    self.tapper = nil;
  }
  
  
  self.tapper = [[UITapGestureRecognizer alloc]
                 initWithTarget:self
                 action:@selector(focusArticle:)];
  self.tapper.numberOfTapsRequired = 1;
  self.tapper.cancelsTouchesInView = YES;
  self.tapper.delaysTouchesBegan = NO;
  self.tapper.delaysTouchesEnded = NO;
  [self.view addGestureRecognizer:self.tapper];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
