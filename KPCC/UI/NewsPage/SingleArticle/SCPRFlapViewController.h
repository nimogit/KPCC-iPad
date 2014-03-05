//
//  SCPRFlapViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/11/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
  FlapPositionUnknown = 0,
  FlapPositionLeft,
  FlapPostitionRight
} FlapPosition;

@interface SCPRFlapViewController : UIViewController

@property (nonatomic) BOOL rightFlap;
@property (nonatomic,strong) IBOutlet UIView *flapBody;
@property (nonatomic,strong) IBOutlet UIView *shadowView;
@property (nonatomic,strong) IBOutlet UIView *slidePieceView;
- (void)attachFlapToView:(id)view inPosition:(FlapPosition)position;

@end
