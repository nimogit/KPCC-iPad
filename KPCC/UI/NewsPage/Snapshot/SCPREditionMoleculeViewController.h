//
//  SCPREditionMoleculeViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 7/23/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPREditionAtomViewController.h"
#import "global.h"

@interface SCPREditionMoleculeViewController : UIViewController<Backable,UIScrollViewDelegate,Rotatable>

@property (nonatomic,strong) IBOutlet UIScrollView *scroller;
@property (nonatomic,strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic,strong) IBOutlet UIButton *backButton;
@property (nonatomic,strong) NSMutableArray *editions;
@property (nonatomic,strong) NSMutableArray *displayVector;
@property (nonatomic,weak) SCPREditionAtomViewController *currentAtom;
@property (nonatomic,strong) id parentEditionContentViewController;
@property NSInteger currentIndex;
@property NSInteger moleculeIndex;
@property BOOL fromNewsPage;
@property (nonatomic,strong) NSDictionary *editionShell;
@property (nonatomic,strong) IBOutlet UILabel *editionInfoLabel;
@property (nonatomic,strong) IBOutlet UIView *infoSeatView;

- (void)setupWithEditions:(NSMutableArray*)editions andIndex:(NSInteger)index;
- (void)setupWithEdition:(NSDictionary*)edition andIndex:(NSInteger)index;
- (void)pushToAtomDetails:(NSInteger)index;
- (void)pushToCurrentAtomDetails;
- (void)sendAnalysis;

@end
