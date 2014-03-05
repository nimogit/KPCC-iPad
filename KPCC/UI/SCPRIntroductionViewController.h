//
//  SCPRIntroductionViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 11/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

typedef enum {
  CardTypeWelcome = 0,
  CardTypeTheShortList,
  CardTypeLiveStream,
  CardTypeDrawer,
  CardTypePrograms,
  CardTypeQueue,
  CardTypeNone
} CardType;

@interface SCPRIntroductionViewController : UIViewController<Rotatable,Cloakable,UIScrollViewDelegate>

@property (nonatomic,strong) IBOutlet UIScrollView *cardScroller;
@property (nonatomic,strong) NSMutableArray *cardVector;
@property CardType currentCard;

- (void)buildIntro;
- (void)nextCard;
- (void)finishTour;

@end
