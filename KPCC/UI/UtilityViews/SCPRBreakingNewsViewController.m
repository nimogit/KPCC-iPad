//
//  SCPRBreakingNewsViewController.m
//  KPCC
//
//  Created by Hochberg, Ben on 9/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRBreakingNewsViewController.h"

@interface SCPRBreakingNewsViewController ()

@end

@implementation SCPRBreakingNewsViewController

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
  
  
  self.swiper = [[UISwipeGestureRecognizer alloc]
                 initWithTarget:self
                 action:@selector(swiped)];
  [self.swiper setDirection:UISwipeGestureRecognizerDirectionUp];
  
  [self.view addGestureRecognizer:self.swiper];
  
  self.view.layer.borderColor = [[DesignManager shared] silverliningColor].CGColor;
  self.view.layer.borderWidth = 1.0;
  
  [self.categoryLabel titleizeText:self.categoryLabel.text
                              bold:YES];
  [self.timestampLabel titleizeText:self.timestampLabel.text
                               bold:NO];
  
  self.timestampLabel.textColor = [[DesignManager shared] silverTextColor];
  self.view.backgroundColor = [[DesignManager shared] silverCurtainsColor];
  
    // Do any additional setup after loading the view from its nib.
}

- (void)showOnView:(UIViewController *)viewController withMessage:(NSString *)message action:(BreakingInteractionCallback)action {
  [self showOnView:viewController
       withMessage:message
   actionOnDismiss:NO
            action:action];
}

- (void)showOnView:(UIViewController *)viewController withMessage:(NSString *)message actionOnDismiss:(BOOL)actionOnDismiss action:(BreakingInteractionCallback)action  {
  if ( !self.showing ) {
    self.view.frame = CGRectMake(0.0,-1.0*self.view.frame.size.height,
                                 viewController.view.bounds.size.width,
                                 self.view.frame.size.height);
    self.view.alpha = 0.0;
    

  }
  
  NSLog(@"*** BREAKING NEWS *** Screen width: %1.1f",viewController.view.bounds.size.width);
  
  if ( self.interactionButton ) {
    [self.interactionButton removeFromSuperview];
    self.interactionButton = nil;
  }
  
  self.action = action;
  self.actionOnDismiss = actionOnDismiss;
  
  NSString *pretty = [[NSDate date] prettyCompare:[NSDate date]];
  [self.timestampLabel titleizeText:[pretty uppercaseString]
                               bold:NO];
  
  self.interactionButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0,0.0,self.cardContentView.frame.size.width,
                                                                      self.cardContentView.frame.size.height)];
  [self.cardContentView addSubview:self.interactionButton];
  
  [self.interactionButton addTarget:self
                             action:@selector(buttonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
  

  [self.breakingHeadlineLabel sansifyTitleText:message
                                                              bold:YES
                                                     respectHeight:YES];
  
  if ( !self.showing ) {
    [viewController.view addSubview:self.view];
    [viewController.view bringSubviewToFront:self.view];
    [UIView animateWithDuration:0.33 animations:^{
      self.view.alpha = 1.0;
      self.view.frame = CGRectMake(0.0,0.0,
                                                     viewController.view.bounds.size.width,
                                                     self.view.frame.size.height);
    } completion:^(BOOL finished) {
      self.showing = YES;
    }];
  }
}

- (void)hide {
  if ( !self.showing ) {
    return;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"breaking_news_dismissed"
                                                        object:nil];
  });
  
  [UIView animateWithDuration:0.33 animations:^{
    self.view.alpha = 0.0;
    self.view.frame = CGRectMake(0.0,-1.0*self.view.frame.size.height,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
  } completion:^(BOOL finished) {
    self.showing = NO;
    [self.view removeFromSuperview];

  }];
}

- (void)swiped {
  [self hide];
}

- (void)buttonTapped:(id)sender {
  dispatch_async(dispatch_get_main_queue(), self.action);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
