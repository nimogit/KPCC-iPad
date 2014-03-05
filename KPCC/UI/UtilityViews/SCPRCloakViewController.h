//
//  SCPRCloakViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@interface SCPRCloakViewController : UIViewController<Rotatable>

@property (nonatomic,strong) id cloakContent;
@property CGFloat rotationNudge;

@end
