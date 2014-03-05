//
//  SCPRSimpleNewsViewController.h
//  KPCC
//
//  Created by Ben Hochberg on 5/6/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRTileViewController.h"
#import "global.h"
#import "SCPRSpinnerViewController.h"

typedef enum {
  ScrollDirectionUnknown = 0,
  ScrollDirectionLeft,
  ScrollDirectionRight
} ScrollDirection;

@interface SCPRSimpleNewsViewController : UIViewController<ContentContainer,UIScrollViewDelegate> {
  
}

- (void)processArticles:(NSArray*)articles;
- (void)setup;
- (void)setupForTopic:(NSString*)topic padding:(BOOL)padding;
- (void)autoFlip:(UIScrollView*)scroller newFrame:(NSValue*)frame direction:(NSInteger)directior;

- (void)disarm;
- (void)arm;

@property (nonatomic,strong) IBOutlet NSArray *articles;
@property NSInteger stackPointer;
@property BOOL rearmOnAppearance;
@property BOOL okToTrashPushed;

@property (nonatomic,strong) IBOutlet UIScrollView *quad1;
@property (nonatomic,strong) IBOutlet UIScrollView *quad2;
@property (nonatomic,strong) IBOutlet UIScrollView *quad3;
@property (nonatomic,strong) IBOutlet UIScrollView *quad4;

@property (nonatomic,strong) IBOutlet UIView *containerView;

@property (nonatomic,strong) NSMutableDictionary *articleRetainer;
@property (nonatomic,weak) id<ContentProcessor> contentDelegate;
@property (nonatomic,weak) id parentContainer;
@property (nonatomic,strong) id pushed;
@property (nonatomic,strong) NSArray *schema;

@property (nonatomic,strong) NSTimer *timer1;
@property (nonatomic,strong) NSTimer *timer2;
@property (nonatomic,strong) NSTimer *timer3;
@property (nonatomic,strong) NSTimer *timer4;

@property (nonatomic,strong) NSTimer *flipTimer1;
@property (nonatomic,strong) NSTimer *flipTimer2;
@property (nonatomic,strong) NSTimer *flipTimer3;
@property (nonatomic,strong) NSTimer *flipTimer4;

@property CGPoint anchoredOffset1;
@property CGPoint anchoredOffset2;
@property CGPoint anchoredOffset3;
@property CGPoint anchoredOffset4;

@property NSNumber *direction1;
@property NSNumber *direction2;
@property NSNumber *direction3;
@property NSNumber *direction4;


@property (nonatomic,strong) NSMutableDictionary *paddingHash;

@property (nonatomic,strong) NSMutableArray *bounceQueue;
@property (nonatomic,strong) NSMutableDictionary *scrollLocks;

@property NSInteger loadCount;

@property (nonatomic,strong) SCPRSpinnerViewController *spinner;

@property (nonatomic,strong) NSMutableArray *displayQueue;

@end
