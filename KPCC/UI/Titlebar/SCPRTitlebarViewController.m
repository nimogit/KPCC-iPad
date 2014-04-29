//
//  SCPRTitlebarViewController.m
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRTitlebarViewController.h"
#import "SCPRViewController.h"
#import "SCPRMasterRootViewController.h"
#import "SCPRNewsSectionTableViewController.h"


#import "global.h"

@interface SCPRTitlebarViewController ()

@end

@implementation SCPRTitlebarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.drawerButton.accessibilityLabel = @"Menu";
  
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.editButton.titleLabel.font.pointSize]
                                forButton:self.donateButton];
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.editButton.titleLabel.font.pointSize]
                                forButton:self.signoutButton];
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] pumpkinColor]
                                     forButton:self.donateButton];
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.editButton.titleLabel.font.pointSize]
                                forButton:self.categoriesButton];
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.editButton.titleLabel.font.pointSize]
                                forButton:self.closeCategoriesButton];
  
  [self.donateButton addTarget:self
                        action:@selector(buttonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  
  self.navStack = [[NSMutableArray alloc] init];
  self.originalLeftButtonFrame = self.drawerButton.frame;
  [[DesignManager shared] globalSetFontTo:[[DesignManager shared] latoRegular:self.editButton.titleLabel.font.pointSize]
                                forButton:self.editButton];
}


- (void)buttonTapped:(id)sender {
  if (sender == self.drawerButton) {
    SCPRAppDelegate *del = [Utilities del];
    [del toggleDrawer];
  }
  if (sender == self.backButton) {
    [self.container backTapped];
  }
  if (sender == self.personalInfoButton) {
    SCPRViewController *mvc = [[Utilities del] viewController];
    [mvc toggleShareDrawer];
  }
  if (sender == self.donateButton) {
    [[AnalyticsManager shared] logEvent:@"tap_donate" withParameters:@{}];
    NSURL *url = [NSURL URLWithString:kDonateURL];
    [[UIApplication sharedApplication] openURL:url];
  }
  if (sender == self.categoriesButton) {
    [self.delegate openSectionsTapped];
    [self applyCloseCategoriesButton];
  }
  if (sender == self.closeCategoriesButton) {
    //[[[Utilities del] viewController] dismissViewControllerAnimated:YES completion:nil];
    [self.delegate closeSectionsTapped];
    [self eraseCloseCategoriesButton];
    [self applyCategoriesButton];
  }
}

- (void)morph:(BarType)barType container:(id<Backable>)container {
  
  self.reduced = NO;

  if (barType != BarTypeDrawer && !self.popping) {
    [self pushStyle];
  }
  
  // Remove old subviews from titleBar
  for (UIView *v in [self.view subviews]) {
    [v removeFromSuperview];
  }

  [self.parserOrFullButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
  
  [self.editButton removeTarget:nil
                         action:NULL
               forControlEvents:UIControlEventAllEvents];
  
  [self.personalInfoButton removeTarget:nil
                                 action:NULL
                       forControlEvents:UIControlEventAllEvents];
  
  [[DesignManager shared] globalSetTitleTo:@"EDIT FAVORITES"
                                 forButton:self.editButton];
  [[DesignManager shared] globalSetImageTo:@"queue_pencil_button.png"
                                 forButton:self.editButton];
  [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] gloomyCloudColor]
                                     forButton:self.editButton];

  self.previousBarType = self.barType;
  self.previousContainer = self.container;

  if (self.observableScroller) {
    self.observableScroller = nil;
  }
  
  if ([container respondsToSelector:@selector(titlebarTraversalScroller)]) {
    self.observableScroller = [container titlebarTraversalScroller];
  }

  self.barType = barType;

  switch (barType) {
    case BarTypeDrawer:
      self.personalInfoButton.alpha = 0.0;
      self.drawerButton.frame =   CGRectMake(10.0,
                                             0.0,
                                             self.drawerButton.frame.size.width,
                                             self.drawerButton.frame.size.height);
      
      [self.view addSubview:self.drawerButton];
      
      break;
      
    case BarTypeModal:
      self.suppressDonate = YES;
      [self.view addSubview:self.backButtonSeat];

      self.container = container;
      [self applyBackButtonText:@"NEWS"];

      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      [self applySharingButton];
      
      break;
    case BarTypeEditions:
    {
      [self applyClearBackground];
      [self.view addSubview:self.backButtonSeat];
      
      self.container = container;
      [self applyBackButtonText:@"Short List"];
      
      [self applyKpccLogo];
      
      break;
    }
    case BarTypeExternalWeb:
    {
      self.suppressDonate = YES;
      self.backButtonSeat.frame = CGRectMake(0.0,
                                             0.0,
                                             self.backButtonSeat.frame.size.width,
                                             self.backButtonSeat.frame.size.height);
      
      [self.view addSubview:self.backButtonSeat];
      
      if (self.reduced) {
        [[DesignManager shared] globalSetImageTo:@"website_icon.png"
                                       forButton:self.parserOrFullButton];
      } else {
        [[DesignManager shared] globalSetImageTo:@"glasses.png"
                                       forButton:self.parserOrFullButton];
      }
      
      [self applySharingButton];
      
      [self.view addSubview:self.parserOrFullButton];
      
      [[DesignManager shared] avoidNeighbor:self.personalInfoButton
                                   withView:self.parserOrFullButton
                                  direction:NeighborDirectionToRight
                                    padding:10.0];
      
      [[DesignManager shared] alignVerticalCenterOf:self.personalInfoButton
                                           withView:self.parserOrFullButton];

      self.container = container;
      [self applyBackButtonText:@"Back"];
      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      
      break;
    }
    case BarTypeProgramAtoZ:
    {
      self.suppressDonate = YES;
      self.personalInfoButton.alpha = 0.0;
      self.drawerButton.frame =   CGRectMake(10.0,
                                             0.0,
                                             self.drawerButton.frame.size.width,
                                             self.drawerButton.frame.size.height);
      [self.view addSubview:self.drawerButton];
      
      [self.view addSubview:self.editButton];
      
      self.editButton.frame = CGRectMake(self.view.frame.size.width-self.editButton.frame.size.width,
                                         0.0,
                                         self.editButton.frame.size.width,
                                         self.editButton.frame.size.height);
      
      self.originalEditButtonInsets = self.editButton.titleEdgeInsets;
      
      self.editButton.center = CGPointMake(self.editButton.center.x,
                                                   self.view.frame.size.height/2.0);
      
      [self.view addSubview:self.pageTitleLabel];
      
      [self.pageTitleLabel titleizeText:@"" bold:NO];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] gloomyCloudColor]
                                         forButton:self.editButton];
      
      self.pageTitleLabel.textColor = [[DesignManager shared] gloomyCloudColor];
      
      self.pageTitleLabel.center = CGPointMake(self.view.frame.size.width/2.0,
                                               self.view.frame.size.height/2.0);

      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      
      [Utilities primeTitlebarWithText:@"ALL PROGRAMS" shareEnabled:NO container:nil];
      
      break;
    }
    case BarTypeProgramSingle:
      
      self.suppressDonate = YES;
      [self eraseDonateButton];
      
      [self.view addSubview:self.backButtonSeat];
      
      self.container = container;
      [self applyBackButtonText:@"Programs"];
      
      break;
      
    case BarTypeDrawerWithCategories:

      self.suppressDonate = YES;
      self.personalInfoButton.alpha = 0.0;
      self.drawerButton.frame =   CGRectMake(10.0,
                                             0.0,
                                             self.drawerButton.frame.size.width,
                                             self.drawerButton.frame.size.height);
      
      [self.view addSubview:self.drawerButton];
      
      [self applyKpccLogo];
      [self applyCategoriesButton];
      
      break;

    case BarTypeUnknown:
      break;
      
  }
  
  if ( !self.suppressDonate ) {
    if ( ![[SocialManager shared] isAuthenticatedWithMembership] ) {
      [self applyDonateButton];
    }
  } else {
    self.suppressDonate = NO;
  }

}

- (void)eraseDonateButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.donateButton setAlpha:0.0];
    [self.donateButton removeFromSuperview];
  }];
}

- (void)applyDonateButton {
  [self eraseCategoriesButton];
  [self.view addSubview:self.donateButton];

  self.donateButton.frame = CGRectMake(self.view.frame.size.width - self.donateButton.frame.size.width - 2.0,
                                       0.0,
                                       self.donateButton.frame.size.width,
                                       self.donateButton.frame.size.height);
  self.donateButton.center = CGPointMake(self.donateButton.center.x,
                                         self.view.frame.size.height / 2.0);
  [UIView animateWithDuration:0.22 animations:^{
    [self.donateButton setAlpha:1.0];
  }];
}

- (void)applySignoutButton {
  [self eraseDonateButton];
  [self.view addSubview:self.signoutButton];

  self.signoutButton.frame = CGRectMake(self.view.frame.size.width - self.signoutButton.frame.size.width - 10.0,
                                        0.0,
                                        self.signoutButton.frame.size.width,
                                        self.signoutButton.frame.size.height);
  self.signoutButton.center = CGPointMake(self.signoutButton.center.x,
                                          self.view.frame.size.height / 2.0);
  [UIView animateWithDuration:0.22 animations:^{
    [self.signoutButton setAlpha:1.0];
  }];
}

- (void)eraseCategoriesButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.categoriesButton setAlpha:0.0];
    [self.categoriesButton removeFromSuperview];
  }];
}

- (void)applyCategoriesButton {
  
  if ([self.view.subviews containsObject:self.closeCategoriesButton]) {
    return;
  }

  [self eraseDonateButton];
  //[self eraseCloseCategoriesButton];
  [self.view addSubview:self.categoriesButton];
  
  self.categoriesButton.frame = CGRectMake(self.view.frame.size.width - self.categoriesButton.frame.size.width - 10.0,
                                           0.0,
                                           self.categoriesButton.frame.size.width,
                                           self.categoriesButton.frame.size.height);
  self.categoriesButton.center = CGPointMake(self.categoriesButton.center.x,
                                             self.view.frame.size.height / 2.0);
  [UIView animateWithDuration:0.22 animations:^{
    [self.categoriesButton setAlpha:1.0];
  }];
}

- (void)eraseCloseCategoriesButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.closeCategoriesButton setAlpha:0.0];
    [self.closeCategoriesButton removeFromSuperview];
  }];
}

- (void)applyCloseCategoriesButton {
  [self eraseCategoriesButton];
  [self eraseDonateButton];
  [self.view addSubview:self.closeCategoriesButton];
  
  
  self.closeCategoriesButton.frame = CGRectMake(self.view.frame.size.width - self.closeCategoriesButton.frame.size.width - 10.0,
                                           0.0,
                                           self.closeCategoriesButton.frame.size.width,
                                           self.closeCategoriesButton.frame.size.height);
  self.closeCategoriesButton.center = CGPointMake(self.closeCategoriesButton.center.x,
                                             self.view.frame.size.height / 2.0);
  
  [UIView animateWithDuration:0.22 animations:^{
    [self.closeCategoriesButton setAlpha:1.0];
  }];
}

- (void)pushStyle {
  [self pushStyle:YES];
}

/******************************************************/
// -- Developer Note --
// This function is called every time "morph" is called UNLESS it's popping the stack in which case it's ignored.
// As a result, you probably will never need to call this method directly. Instead call morph.
//
// This is a method that helps save the state of the titlebar before it's changed by a view that's about to be pushed on top
// of the current view. Keep in mind that this method should be updated if the titlebar's basic function needs to be altered.
// Study this method closely to see what's happening in it, and then look at the pop: method
//
- (void)pushStyle:(BOOL)truePush {
  NSMutableDictionary *state = [[NSMutableDictionary alloc] init];
  if (self.container) {
    [state setObject:self.container
              forKey:@"container"];
  }
  [state setObject:self.view.backgroundColor
            forKey:@"bgcolor"];
  
  if ( self.backButton.titleLabel.text ) {
    [state setObject:self.backButton.titleLabel.text
              forKey:@"backtitle"];
  }
  [state setObject:[self.view subviews]
            forKey:@"subviews"];
  [state setObject:[NSNumber numberWithInt:self.barType]
            forKey:@"type"];
  
  [state setObject:[NSNumber numberWithInt:self.pager.numberOfPages]
            forKey:@"pageCount"];
  
  [state setObject:[NSNumber numberWithInt:self.pager.currentPage]
            forKey:@"currentPage"];
  
  for (id v in [self.view subviews]) {
    if ([v isKindOfClass:[UIPageControl class]]) {
      [state setObject:@1 forKey:@"hasPager"];
    }
    if (v == self.donateButton) {
      [state setObject:@1 forKey:@"hasDonate"];
    }
  }
  
  if (truePush) {
    [self.navStack addObject:state];
  } else {
    self.currentState = state;
  }
}

- (void)pop:(BOOL)truePop {
  if ( self.navStack.count == 0 ) {
    return;
  }
  
  self.suppressDonate = YES;
  self.popping = YES;
  
  @try {
    
    NSDictionary *items = nil;
    if (truePop) {
      items = [self.navStack lastObject];
    } else {
      items = self.currentState;
    }
    
    if (items) {
      if ([items objectForKey:@"container"]) {
        [self morph:(BarType)[[items objectForKey:@"type"] intValue]
          container:[items objectForKey:@"container"]];
      } else {
        [self morph:(BarType)[[items objectForKey:@"type"] intValue]
          container:nil];
      }
      
      self.view.backgroundColor = [items objectForKey:@"bgcolor"];
      NSArray *svs = [items objectForKey:@"subviews"];
      for (UIView *v in svs) {
        [self.view addSubview:v];
      }
      
      if ([items objectForKey:@"backtitle"]) {
        [self applyBackButtonText:[items objectForKey:@"backtitle"]];
      }
      
      if ([items objectForKey:@"pageCount"]) {
        self.pager.numberOfPages = [[items objectForKey:@"pageCount"] intValue];
      }
      
      if ([items objectForKey:@"currentPage"]) {
        self.pager.currentPage = [[items objectForKey:@"currentPage"] intValue];
        
      }
      
      if ([items objectForKey:@"hasPager"]) {
        [self applyPagerWithCount:self.pager.numberOfPages currentPage:self.pager.currentPage];
      }
      
      NSNumber *donate = [items objectForKey:@"hasDonate"];
      if ([items objectForKey:@"hasDonate"]) {
        if ([donate intValue] == 1) {
          [self applyDonateButton];
        }
      }
      
      if (truePop) {
        [self.navStack removeLastObject];
      }
    }
  } @catch (NSException *e) {
    NSLog(@"Exception when popping titlebar : %@",[e description]);
  }
  
  self.popping = NO;
}

- (void)restamp {
  if (self.barType == BarTypeEditions) {
    [self applyPagerWithCount:self.pager.numberOfPages currentPage:self.pager.currentPage];
  }
}

- (void)pop {
  [self pop:YES];
}

- (void)applyClearBackground {
  [UIView animateWithDuration:0.22 animations:^{
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
  }];
}

- (void)applyOnyxBackground {
  [UIView animateWithDuration:0.22 animations:^{
    self.view.layer.backgroundColor = [[DesignManager shared] onyxColor].CGColor;
  }];
}

- (void)applyBackButtonText:(NSString *)backButtonText {
  
  if ( [backButtonText length] < [@"PHOTO & VIDEO" length] ) {
    NSInteger diff = abs([backButtonText length]-[@"PHOTO & VIDEO" length]);
    for (unsigned i = 0; i < diff-1; i++) {
      backButtonText = [backButtonText stringByAppendingString:@"   "];
    }
  }
  
  backButtonText = [backButtonText lowercaseString];
  backButtonText = [backButtonText capitalizedString];
  
  [self.backButtonText titleizeText:backButtonText
                               bold:NO
                      respectHeight:NO];

  self.backButtonSeat.frame = CGRectMake(0.0,
                                         self.backButtonSeat.frame.origin.y,
                                         self.backButtonSeat.frame.size.width,
                                         self.backButtonSeat.frame.size.height);
}

- (void)applySharingButton {
  [self eraseDonateButton];
  
  self.personalInfoButton.alpha = 1.0;
  self.personalInfoButton.frame = CGRectMake(self.view.frame.size.width - self.personalInfoButton.frame.size.width - 10.0,
                                             0.0,
                                             self.personalInfoButton.frame.size.width,
                                             self.personalInfoButton.frame.size.height);
  self.personalInfoButton.center = CGPointMake(self.personalInfoButton.center.x,
                                               self.view.frame.size.height / 2.0);

  [[DesignManager shared] globalSetTitleTo:@"SHARE"
                                 forButton:self.personalInfoButton];

  [[DesignManager shared] globalSetImageTo:@"icon-share-active.png"
                                 forButton:self.personalInfoButton];

  [self.view addSubview:self.personalInfoButton];
  [self.personalInfoButton addTarget:[[Utilities del] viewController]
                              action:@selector(toggleShareDrawer)
                    forControlEvents:UIControlEventTouchUpInside];
}

- (void)applyEditionsLabel {
  [self.view addSubview:self.editionsLogo];
  
  self.editionsLogo.center = CGPointMake(self.view.frame.size.width / 2.0,
                                         self.view.frame.size.height / 2.0);
}

- (void)applyKpccLogo {
  [self.view addSubview:self.kpccLogo];
  
  self.kpccLogo.center = CGPointMake(self.view.frame.size.width / 2.0,
                                         self.view.frame.size.height / 2.0);
}

- (void)applyPagerWithCount:(NSInteger)count currentPage:(NSInteger)currentPage {
  
  [self eraseDonateButton];
  [self.pager removeFromSuperview];
  [self.view addSubview:self.pager];
  self.pager.numberOfPages = count;
  CGFloat nudge = 0.0;
  if (count >= 14) {
    nudge = 20.0;
  }
  self.pager.frame = CGRectMake(self.view.frame.size.width - self.pager.frame.size.width - 20.0 - nudge,
                                self.view.frame.size.height / 2.0 - (self.pager.frame.size.height / 2.0),
                                self.pager.frame.size.width,
                                self.pager.frame.size.height);
  self.pager.currentPage = currentPage;
  self.pager.userInteractionEnabled = NO;
}

- (void)applyGrayBackground {
  self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
}

- (void)toggleReduced:(BOOL)reduced {
  self.reduced = reduced;
  
  if (!self.reduced) {
    [[DesignManager shared] globalSetImageTo:@"glasses.png"
                                   forButton:self.parserOrFullButton];
  } else {
    [[DesignManager shared] globalSetImageTo:@"website_icon.png"
                                   forButton:self.parserOrFullButton];
  }
}

- (BOOL)isDonateButtonShown {
  NSDate *methodStart = [NSDate date];
  
  BOOL donateShown = [self.view.subviews containsObject:self.donateButton];
  
  NSDate *methodFinish = [NSDate date];
  NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
  NSLog(@"!! - donateButtonShown - executionTime = %f", executionTime);
  
  return donateShown;
  //return ([self.view.subviews containsObject:self.donateButton]);
}

- (BOOL)isCategoriesButtonShown {
  return ([self.view.subviews containsObject:self.categoriesButton]);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
