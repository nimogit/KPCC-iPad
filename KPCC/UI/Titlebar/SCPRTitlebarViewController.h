//
//  SCPRTitlebarViewController.h
//  KPCC
//
//  Created by Ben on 4/16/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

typedef enum {
  BarTypeUnknown = 0,
  BarTypeDrawer,
  BarTypeModal,
  BarTypeEditions,
  BarTypeExternalWeb,
  BarTypeProgramAtoZ,
  BarTypeProgramSingle
} BarType;

@protocol SCPRTitlebarDelegate <NSObject>
@optional
- (void)openSectionsTapped;
- (void)closeSectionsTapped;
@end

@interface SCPRTitlebarViewController : UIViewController {
  UIButton *_drawerButton;
  UIButton *_personalInfoButton;
}

- (IBAction)buttonTapped:(id)sender;

@property (nonatomic,strong) IBOutlet UIButton *drawerButton;
@property (nonatomic,strong) IBOutlet UIButton *personalInfoButton;
@property (nonatomic,strong) IBOutlet UIButton *parserOrFullButton;
@property (nonatomic,strong) IBOutlet UIView *specialView;
@property (nonatomic,strong) IBOutlet UIButton *backButton;
@property (nonatomic,strong) IBOutlet UIButton *editButton;
@property (nonatomic,strong) IBOutlet UIButton *signoutButton;
@property (nonatomic,strong) IBOutlet UIButton *categoriesButton;
@property (nonatomic,strong) IBOutlet UIButton *closeCategoriesButton;
@property (nonatomic,strong) IBOutlet UILabel *pageTitleLabel;
@property (nonatomic,strong) IBOutlet UIImageView *editionsLogo;
@property (nonatomic,weak) id<Backable> container;
@property (nonatomic,weak) id<Backable> previousContainer;
@property CGRect originalLeftButtonFrame;
@property BarType barType;
@property BarType previousBarType;
@property (nonatomic,strong) IBOutlet UIPageControl *pager;
@property (nonatomic,weak) UIScrollView *observableScroller;
@property (nonatomic,strong) IBOutlet UIImageView *kpccLogo;
@property (nonatomic,strong) NSMutableArray *navStack;
@property (nonatomic,strong) NSDictionary *currentState;
@property (nonatomic,strong) IBOutlet UIButton *donateButton;
@property (nonatomic,strong) IBOutlet UIView *backButtonSeat;
@property (nonatomic,strong) IBOutlet UILabel *backButtonText;

@property UIEdgeInsets originalEditButtonInsets;

@property BOOL popping;
@property BOOL reduced;
@property BOOL suppressDonate;

@property (nonatomic,weak) id<SCPRTitlebarDelegate> delegate;

- (void)morph:(BarType)barType container:(id<Backable>)container;
- (void)toggleReduced:(BOOL)reduced;
- (void)applyEditionsLabel;
- (void)applyPagerWithCount:(NSInteger)count currentPage:(NSInteger)currentPage;
- (void)applyKpccLogo;
- (void)applyGrayBackground;
- (void)applyOnyxBackground;
- (void)applyClearBackground;
- (void)applyBackButtonText:(NSString*)backButtonText;
- (void)applySharingButton;
- (void)applySignoutButton;
- (void)applyDonateButton;
- (void)applyCategoriesButton;
- (void)applyCloseCategoriesButton;

- (void)applyCategoriesUI;
- (void)removeCategoriesUI;

- (void)eraseDonateButton;
- (void)eraseCategoriesButton;
- (void)eraseCloseCategoriesButton;
- (void)erasePager;

- (void)pushStyle:(BOOL)truePush;
- (void)pushStyle;
- (void)pop;
- (void)pop:(BOOL)truePop;
- (void)restamp;

- (BOOL)isCategoriesButtonShown;
- (BOOL)isDonateButtonShown;

@end
