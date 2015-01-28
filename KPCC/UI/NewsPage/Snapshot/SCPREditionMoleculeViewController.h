//
//  SCPREditionMoleculeViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 7/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPREditionAtomViewController.h"
#import "SCPRDFPViewController.h"

#import "global.h"

@interface SCPREditionMoleculeViewController : UIViewController<Backable,UIScrollViewDelegate,Rotatable,SCPRDFPAdDelegate>

@property (nonatomic,strong) IBOutlet UIScrollView *scroller;
@property (nonatomic,strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic,strong) IBOutlet UIButton *backButton;
@property (nonatomic,strong) NSMutableArray *editions;
@property (nonatomic,strong) NSMutableArray *displayVector;
@property (nonatomic,strong) IBOutlet UIView *cloakView;

@property NSInteger adIndex;
@property (nonatomic,strong) NSMutableDictionary *adConstraints;
@property (nonatomic,strong) NSMutableArray *displayChain;
@property (nonatomic,strong) NSMutableDictionary *pushedConstraints;

@property (nonatomic,strong) SCPRDFPViewController *currentAdController;

@property (nonatomic,weak) SCPREditionAtomViewController *currentAtom;
@property (nonatomic,strong) id parentEditionContentViewController;
@property NSInteger currentIndex;
@property NSInteger moleculeIndex;

@property BOOL fromNewsPage;
@property BOOL needsContentSnap;
@property BOOL needsPush;
@property BOOL intermediaryAppearance;
@property BOOL adIsHot;
@property BOOL dismissalWentLeft;
@property BOOL adIsDisplaying;

@property DismissDirection dismissDirection;

@property (nonatomic,strong) NSLayoutConstraint *leadingConstraint;
@property (nonatomic,strong) NSLayoutConstraint *trailingConstraint;

@property (nonatomic,strong) NSDictionary *editionShell;
@property (nonatomic,strong) IBOutlet UILabel *editionInfoLabel;
@property (nonatomic,strong) IBOutlet UIView *infoSeatView;
@property (nonatomic,strong) NSMutableDictionary *metricChain;


- (void)setupWithEditions:(NSMutableArray*)editions andIndex:(NSInteger)index;
- (void)setupWithEdition:(NSDictionary*)edition andIndex:(NSInteger)index;
- (void)pushToAtomDetails:(NSInteger)index;
- (void)pushToCurrentAtomDetails;
- (void)sendAnalysis;
- (void)snapContentSize;
- (void)snapContentSize:(BOOL)animated;
- (void)insertAdAtIndex:(NSInteger)index;
- (void)removeAdFromIndex:(NSInteger)index;
- (void)removeAdFromIndex:(NSInteger)index adjustPager:(BOOL)adjustPager;

@end
