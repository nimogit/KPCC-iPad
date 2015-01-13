//
//  SCPRProgramNavigatorViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/26/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRAppDelegate.h"

@interface SCPRProgramNavigatorViewController : UIViewController<UIScrollViewDelegate,Rotatable>

@property (nonatomic,strong) IBOutlet UIScrollView *programScroller;
@property (nonatomic,strong) NSMutableArray *programVector;
@property (nonatomic,strong) NSMutableArray *programDataVector;
@property NSInteger currentIndex;
@property NSInteger targetedIndex;
@property NSInteger candidateIndex;
@property (nonatomic,strong) IBOutlet UIView *cloakView;
@property (nonatomic,strong) NSMutableDictionary *metricChain;
@property BOOL needsSnap;

- (void)setupWithPrograms:(NSArray*)programs;
- (void)snap;
- (void)focusShowWithIndex:(NSInteger)index;
- (void)unplug;

@end
