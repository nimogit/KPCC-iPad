//
//  SCPRLogoGeneratorViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/17/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"

@interface SCPRLogoGeneratorViewController : UIViewController

@property (nonatomic,strong) IBOutlet UILabel *logoLabel;

- (UIImage*)renderWithText:(NSString*)text;

@end
