//
//  SCPRFlatShadedButton.m
//  KPCC
//
//  Created by Ben Hochberg on 5/13/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRFlatShadedButton.h"
#import "global.h"

@implementation SCPRFlatShadedButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      [self prime];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    [self prime];
  }
  
  return self;
}

- (void)prime {
  self.layer.cornerRadius = 4.0;
  self.clipsToBounds = YES;
  
  if ( self.special ) {
    self.layer.cornerRadius = 0.0;

  } else {
    [self.titleLabel setFont:[[DesignManager shared] headlineFontBold:14.0]];
    [self setTitleColor:[UIColor whiteColor]
             forState:UIControlStateNormal];
    [self setTitleColor:[[DesignManager shared] obsidianColor:0.8]
             forState:UIControlStateHighlighted];
    self.titleLabel.shadowColor = [[DesignManager shared] shadowColor];
    self.titleLabel.shadowOffset = CGSizeMake(0.0,1.0);
    self.shadeColor = [UIColor lightGrayColor];
  }

}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
  
}


- (void)setShadeColor:(UIColor *)shadeColor {
  _shadeColor = shadeColor;
  
  CGFloat alpha = self.special ? 1.0 : 0.5;
  
  const CGFloat *components = CGColorGetComponents(shadeColor.CGColor);
  UIColor *translucent = [UIColor colorWithRed:components[0]
                                         green:components[1]
                                          blue:components[2]
                                         alpha:alpha];
  self.backgroundColor = translucent;
  
  
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  if ( highlighted ) {
    
    const CGFloat *components = CGColorGetComponents(self.shadeColor.CGColor);
    UIColor *translucent = [UIColor colorWithRed:components[0]
                                           green:components[1]
                                            blue:components[2]
                                           alpha:1.0];
    
    self.backgroundColor = translucent;
  } else {
    const CGFloat *components = CGColorGetComponents(self.shadeColor.CGColor);
    UIColor *translucent = [UIColor colorWithRed:components[0]
                                           green:components[1]
                                            blue:components[2]
                                           alpha:0.5];
    
    self.backgroundColor = translucent;
  }
}

@end
