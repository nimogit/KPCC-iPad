//
//  SCPRShadowingView.m
//  KPCC
//
//  Created by Ben on 4/15/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRShadowingView.h"
#import "global.h"

@implementation SCPRShadowingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {

  }
  return self;
}

- (void)attachToView:(UIView *)view managedBy:(UIView *)parentView {
  self.viewToShadow = view;
  self.parentView = parentView;
  self.frame = view.frame;
  self.contentMode = UIViewContentModeScaleToFill;
  self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
  self.alpha = 0.0;
  
  [self removeFromSuperview];
  [self.parentView addSubview:self];
  [self.parentView sendSubviewToBack:self];
  
  [[DesignManager shared] applyBaseShadowTo:self];
  
  // Just in case this view has been loaded already remove observation
  if ( self.armed ) {
    [self.viewToShadow removeObserver:self forKeyPath:@"frame"];
    [self.viewToShadow removeObserver:self forKeyPath:@"alpha"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
  [self.viewToShadow addObserver:self
                      forKeyPath:@"frame"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld
                         context:NULL];
  [self.viewToShadow addObserver:self
                      forKeyPath:@"alpha"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                         context:NULL];
  
  self.armed = YES;
  

  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reveal)
                                               name:@"recreate_shadows"
                                             object:nil];
  
}

- (void)reveal {
  [[DesignManager shared] applyBaseShadowTo:self];
  self.alpha = 1.0;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  UIView *objAsView = (UIView*)object;
  if ( [keyPath isEqualToString:@"frame"] ) {
    CGRect newFrame = [[change objectForKey:@"new"] CGRectValue];
    self.frame = newFrame;
  }
  if ( [keyPath isEqualToString:@"alpha"] ) {
    self.alpha = objAsView.alpha;
  }
  
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
