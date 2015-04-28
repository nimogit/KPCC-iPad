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
  
  [self.backButton addTarget:self
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
    if ([self.delegate respondsToSelector:@selector(openSectionsTapped)]) {
      [self.delegate openSectionsTapped];
    }
  }
  if (sender == self.closeCategoriesButton) {
    if ([self.delegate respondsToSelector:@selector(closeSectionsTapped)]) {
      [self.delegate closeSectionsTapped];
    }
  }
}

- (void)morph:(BarType)barType container:(id<Backable>)container {
  
  self.reduced = NO;

  if (barType != BarTypeDrawer && !self.popping) {
    [self pushStyle];
  }
  
  // Remove old subviews from titleBar
  for (UIView *v in [self.view subviews]) {
    v.alpha = 0.0;
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
      self.drawerButton.alpha = 1.0;
      self.backButtonSeat.alpha = 0.0;
      
      break;
      
    case BarTypeModal:
      self.suppressDonate = YES;
      self.backButtonSeat.alpha = 1.0;
      self.drawerButton.alpha = 0.0;

      self.container = container;
      [self applyBackButtonText:@"NEWS"];

      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      [self applySharingButton];
      
      break;
    case BarTypeEditions:
    {
    
      self.drawerButton.alpha = 0.0;
      self.backButtonSeat.alpha = 1.0;
      
      self.container = container;
      [self applyBackButtonText:@"News"];
      
      [self applyKpccLogo];
      
      break;
    }
    case BarTypeExternalWeb:
    {
      self.suppressDonate = YES;
      self.backButtonSeat.alpha = 1.0;
      self.drawerButton.alpha = 0.0;
      
      if (self.reduced) {
        [[DesignManager shared] globalSetImageTo:@"website_icon.png"
                                       forButton:self.parserOrFullButton];
      } else {
        [[DesignManager shared] globalSetImageTo:@"glasses.png"
                                       forButton:self.parserOrFullButton];
      }
      
      [self applySharingButton];
      self.parserOrFullButton.alpha = 1.0;

      self.container = container;
      [self applyBackButtonText:@"Back"];
      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      
      break;
    }
    case BarTypeProgramAtoZ:
    {
      self.suppressDonate = YES;
      self.personalInfoButton.alpha = 0.0;
      self.drawerButton.alpha = 1.0;
      self.backButtonSeat.alpha = 0.0;
      self.editButton.alpha = 1.0;
      self.pageTitleLabel.alpha = 1.0;
      self.kpccLogo.alpha = 0.0;
      self.editionsLogo.alpha = 0.0;
      
      self.originalEditButtonInsets = self.editButton.titleEdgeInsets;
      
      [self.pageTitleLabel titleizeText:@"" bold:NO];
      
      [[DesignManager shared] globalSetTextColorTo:[[DesignManager shared] gloomyCloudColor]
                                         forButton:self.editButton];
      
      self.pageTitleLabel.textColor = [[DesignManager shared] gloomyCloudColor];

      self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
      
      [Utilities primeTitlebarWithText:@"ALL PROGRAMS" shareEnabled:NO container:nil];
      
      break;
    }
    case BarTypeProgramSingle:
      
      self.suppressDonate = YES;
      [self eraseDonateButton];
      
      self.backButtonSeat.alpha = 1.0;
      self.drawerButton.alpha = 0.0;
      
      self.container = container;
      [self applyBackButtonText:@"Programs"];
      
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
  
  if ( self.backButton.titleLabel.text && !SEQ(self.backButton.titleLabel.text,@"") ) {
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
    if ([v isKindOfClass:[UIPageControl class]] && [(UIView*)v alpha] > 0.0 ) {
      [state setObject:@1 forKey:@"hasPager"];
    }
    if (v == self.donateButton && [(UIView*)v alpha] > 0.0 ) {
      [state setObject:@1 forKey:@"hasDonate"];
    }
    if (v == self.categoriesButton && [(UIView*)v alpha] > 0.0 ) {
      [state setObject:@1 forKey:@"hasCategories"];
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

      NSNumber *categories = [items objectForKey:@"hasCategories"];
      if ([items objectForKey:@"hasCategories"]) {
        if ([categories intValue] == 1) {
          [self applyCategoriesButton];
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
    //self.view.layer.backgroundColor = [UIColor redColor].CGColor;
  }];
}

- (void)applyOnyxBackground {
  [UIView animateWithDuration:0.22 animations:^{
    self.view.layer.backgroundColor = [[DesignManager shared] onyxColor].CGColor;
  }];
}

- (void)applyGrayBackground {
  self.view.backgroundColor = [[DesignManager shared] deepOnyxColor];
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

}

- (void)eraseDonateButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.donateButton setAlpha:0.0];
  }];
}

- (void)applyDonateButton {
  [self eraseSharingButton];
  [self eraseCategoriesButton];
  [self erasePager];

  [UIView animateWithDuration:0.22 animations:^{
    [self.donateButton setAlpha:1.0];
  }];
}

- (void)applySignoutButton {
  [self eraseDonateButton];
  [self erasePager];

  [UIView animateWithDuration:0.22 animations:^{
    [self.signoutButton setAlpha:1.0];
  }];
}

- (void)applyCategoriesUI {
  self.drawerButton.alpha = 0.0;
  [self eraseCategoriesButton];
  [self applyCloseCategoriesButton];
  
  [Utilities primeTitlebarWithText:@"SECTIONS"
                      shareEnabled:NO
                         container:nil];
}

- (void)removeCategoriesUI {

  self.drawerButton.alpha = 1.0;
  [Utilities primeTitlebarWithText:@""
                      shareEnabled:NO
                         container:nil];

  [self eraseCloseCategoriesButton];
  [self applyCategoriesButton];
  [self applyKpccLogo];
  
}

- (void)eraseCategoriesButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.categoriesButton setAlpha:0.0];
  }];
}

- (void)applyCategoriesButton {
  [self eraseDonateButton];
  [self eraseCloseCategoriesButton];
  [self erasePager];

  [UIView animateWithDuration:0.22 animations:^{
    [self.categoriesButton setAlpha:1.0];
  }];
}

- (void)eraseCloseCategoriesButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.closeCategoriesButton setAlpha:0.0];
  }];
}

- (void)applyCloseCategoriesButton {
  [self eraseCategoriesButton];
  [self eraseDonateButton];
  [self erasePager];

  [UIView animateWithDuration:0.22 animations:^{
    [self.closeCategoriesButton setAlpha:1.0];
  }];
}

- (void)applySharingButton {
  [self eraseDonateButton];
  [self erasePager];
  
  self.personalInfoButton.alpha = 1.0;


  [[DesignManager shared] globalSetTitleTo:@"SHARE"
                                 forButton:self.personalInfoButton];

  [[DesignManager shared] globalSetImageTo:@"icon-share-active.png"
                                 forButton:self.personalInfoButton];

  [self.personalInfoButton removeTarget:nil
                                 action:nil
                       forControlEvents:UIControlEventAllEvents];
  
  [self.personalInfoButton addTarget:[[Utilities del] viewController]
                              action:@selector(toggleShareDrawer)
                    forControlEvents:UIControlEventTouchUpInside];
}

- (void)eraseSharingButton {
  [UIView animateWithDuration:0.22 animations:^{
    [self.personalInfoButton setAlpha:0.0];
  }];
}

- (void)applyEditionsLabel {
  self.kpccLogo.alpha = 0.0;
  self.editionsLogo.alpha = 1.0;
  
}

- (void)applyKpccLogo {
  self.editionsLogo.alpha = 0.0;
  self.kpccLogo.alpha = 1.0;
}

- (void)applyPagerWithCount:(NSInteger)count currentPage:(NSInteger)currentPage {
  
  [self eraseDonateButton];
  self.pager.numberOfPages = count;
  self.pager.alpha = 1.0;
  self.pager.currentPage = currentPage;
  self.pager.userInteractionEnabled = NO;
  
}

- (void)erasePager {
  self.pager.alpha = 0.0;
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
  return self.donateButton.alpha > 0.0;
}

- (BOOL)isCategoriesButtonShown {
  return self.categoriesButton.alpha > 0.0;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
