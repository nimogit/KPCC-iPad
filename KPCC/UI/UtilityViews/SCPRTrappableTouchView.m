//
//  SCPRTrappableTouchView.m
//  KPCC
//
//  Created by Hochberg, Ben on 5/17/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRTrappableTouchView.h"
#import "SCPRSingleArticleCollectionViewController.h"

@implementation SCPRTrappableTouchView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  SCPRSingleArticleCollectionViewController *svc = (SCPRSingleArticleCollectionViewController*)self.parentContainer;
  svc.gateOpen = YES;
  

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(closeGate)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)closeGate {
  SCPRSingleArticleCollectionViewController *svc = (SCPRSingleArticleCollectionViewController*)self.parentContainer;
  svc.gateOpen = NO;
}

@end
