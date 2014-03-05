//
//  SCPRSmallCutViewController.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/19/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "global.h"

@interface SCPRSmallCutViewController : UIViewController<ContentProcessor> {

}

- (UIImage*)renderWithImage:(NSString*)imageStr;

@property (nonatomic,strong) IBOutlet UIImageView *smallCutImage;
@property CGFloat scale;

@end
