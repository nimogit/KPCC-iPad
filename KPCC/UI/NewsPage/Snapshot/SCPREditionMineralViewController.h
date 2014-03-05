//
//  SCPREditionMineralViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/9/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@interface SCPREditionMineralViewController : UIViewController<UIScrollViewDelegate,Rotatable,ContentProcessor>


- (void)setupWithEditions:(NSArray*)editions;
- (void)unplug;


@property (nonatomic,strong) NSArray *editions;
@property (nonatomic,strong) IBOutlet UIScrollView *editionsScroller;
@property (nonatomic,strong) NSMutableArray *contentVector;
@property (nonatomic,strong) UIPageControl *pageControl;
@property NSInteger currentIndex;
@property BOOL needsRotation;
@property BOOL moleculePushed;
@property (nonatomic,strong) id targetMolecule;

@end
