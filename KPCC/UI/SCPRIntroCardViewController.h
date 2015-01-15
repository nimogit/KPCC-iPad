//
//  SCPRIntroCardViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 11/4/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCPRIntroductionViewController.h"

typedef enum {
  CornerPositionNone = 0,
  CornerPositionNorthwest,
  CornerPositionNortheast,
  CornerPositionSoutheast,
  CornerPositionSouthwest
} CornerPosition;

@interface SCPRIntroCardViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIImageView *splashImage;
@property (nonatomic,strong) IBOutlet UIImageView *ornamentImage;
@property (nonatomic,strong) IBOutlet UIPageControl *pager;
@property (nonatomic,strong) IBOutlet UIButton *nextButton;
@property (nonatomic,weak) id parentIntro;
@property CardType cardType;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *buttonCenterXAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *buttonCenterYAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *cardTopAnchor;
@property (nonatomic, strong) NSArray *cornerImageAnchors;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *cornerImageTmpSizeX;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *cornerImageTmpSizeY;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *cornerImageLeftAnchor;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *cornerImageTopAnchor;

@property BOOL needsSnap;

- (void)setupForCardType:(CardType)type;
- (void)placeOrnamentInCorner:(CornerPosition)position;

@end
