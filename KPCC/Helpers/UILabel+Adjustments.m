//
//  UILabel+Adjustments.m
//  KPCC
//
//  Created by Ben Hochberg on 4/22/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "UILabel+Adjustments.h"
#import <CoreText/CoreText.h>
#include <mach/mach_time.h>
#include <stdint.h>

@implementation UILabel (Adjustments)



- (void)snapText:(NSString *)text bold:(BOOL)bold {
  [self snapText:text bold:bold respectHeight:NO];  
}

- (void)snapText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight {
  NSString *fontName = bold ? @"PTSans-Bold" : @"PTSerif-Regular";
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:fontName];
}

- (void)titleizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight {
  NSString *fontName = bold ? @"Lato-Bold" : @"Lato-Regular";
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:fontName];
}

- (void)titleizeText:(NSString *)text bold:(BOOL)bold {
  NSString *fontName = bold ? @"Lato-Bold" : @"Lato-Regular";
  [self setFont:[UIFont fontWithName:fontName size:self.font.pointSize]];
  self.text = text;
}

- (void)sansifyTitleText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight {
  [self sansifyTitleText:text bold:bold respectHeight:respectHeight centered:NO];
}

- (void)sansifyTitleText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight centered:(BOOL)centered {
  
  if ( !text || (id)text == [NSNull null] ) {
    text = @"";
  }

  NSString *fontName = bold ? @"Lato-Black" : @"Lato-Bold";
  [self setFont:[UIFont fontWithName:fontName size:self.font.pointSize]];
  
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  CGFloat ls = [Utilities isIOS7] ? 0.0 : 0.0;
  
  [style setLineSpacing:ls];
  [style setMaximumLineHeight:self.font.pointSize];
  [style setMinimumLineHeight:self.font.pointSize];
  [style setParagraphSpacing:1.0];
  [style setLineBreakMode:NSLineBreakByTruncatingTail];
  if ( centered ) {
    [style setAlignment:NSTextAlignmentCenter];
  }
  
  NSAttributedString *str = [[NSAttributedString alloc] initWithString:text
                                                            attributes:@{ NSParagraphStyleAttributeName : style}];
  
  if ( !str ) {
    str = [[NSAttributedString alloc] initWithString:@""
                                          attributes:@{ NSParagraphStyleAttributeName : style}];
  }
  
  self.attributedText = str;
  
  if ( respectHeight ) {
    CGSize s = [Utilities isIOS7] ? [str.string sizeOfStringWithFont:self.font
                                                   constrainedToSize:CGSizeMake(self.frame.size.width+3.0,MAXFLOAT)] :
    [str.string sizeOfStringWithFont:self.font
                   constrainedToSize:CGSizeMake(self.frame.size.width+3.0,MAXFLOAT)
     lineBreakMode:NSLineBreakByTruncatingTail];
    
    CGFloat heightToUse = s.height;
    CGFloat approximateNumberOfLines = self.numberOfLines;
    
    BOOL squish = NO;
    if ( approximateNumberOfLines == 0 ) {
      approximateNumberOfLines = ceilf(self.frame.size.height/self.font.pointSize);
      squish = YES;
    }
    
 
    //heightToUse = s.height > self.frame.size.height ? self.font.pointSize*approximateNumberOfLines+2.0 : s.height;
    
    CGFloat modifier = 2.0;
    //if ( ![Utilities isIOS7] ) {
      modifier = self.font.pointSize*0.08;
    //}
    heightToUse = self.font.pointSize*approximateNumberOfLines+modifier;
    heightToUse = fminf(heightToUse, s.height);
    if ( squish ) {
      CGFloat multiplier = [Utilities isIOS7] ? 0.05 : 0.09;
      CGFloat ps = approximateNumberOfLines*(floorf(self.font.pointSize * multiplier));
      heightToUse -= ps;
    }
    
    if ( ![Utilities isIOS7] ) {
      if ( heightToUse < self.font.pointSize ) {
        heightToUse = ceilf(self.font.pointSize + (self.font.pointSize*.05));
      } else {
        heightToUse += modifier;
      }
    }
    
    NSInteger xLines = [self approximateNumberOfLines];
    CGSize hlSizeGuess = [self.attributedText.string sizeOfStringWithFont:self.font
                                                  constrainedToSize:CGSizeMake(self.frame.size.width+3.0,
                                                                               MAXFLOAT)];
    
    if ( xLines == 2 ) {
      if ( abs(hlSizeGuess.height-(self.font.pointSize+modifier)) < modifier ) {
        // Actually only 1 line, this is an "inbetween frame"
        heightToUse = ceilf(self.font.pointSize)+modifier;
      }
    }
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width+3.0,
                            heightToUse);
  }
  
#ifdef FILL_BOUNDARIES
  [self fill];
#endif
  
}

- (NSInteger)approximateNumberOfLines {
  NSInteger h = (int)floorf(self.frame.size.height/(self.font.pointSize+1.0));
  if ( h == 0 ) {
    return 1;
  }
  
  return h;
}

- (void)thickerText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight {
  
  NSString *fontName = bold ? @"Lato-Bold" : @"Lato-Regular";
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:fontName];
  
}

- (void)italicizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight {
  NSString *fontName = bold ? @"Lato-BoldItalic" : @"Lato-Italic";
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:fontName];
}

- (void)titleizeText:(NSString *)text bold:(BOOL)bold contain:(CGRect)contain {

}

- (void)titleizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight lighten:(BOOL)lighten {
  NSString *fontName = bold ? @"Lato-Bold" : @"Lato-Regular";
  if ( lighten ) {
    fontName = @"Lato-Light";
  }
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:fontName];
  
}

- (void)fill {
  NSInteger red = random() % 124;
  NSInteger green = random() % 124;
  NSInteger blue = random() % 124;
  
  CGFloat rC = (CGFloat)red + 128;
  CGFloat gC = (CGFloat)green + 128;
  CGFloat bC = (CGFloat)blue + 128;
  
  self.backgroundColor = [UIColor colorWithRed:rC/255.0
                                         green:gC/255.0
                                          blue:bC/255.0
                                         alpha:1.0];
}

- (void)standardizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight withFont:(NSString *)font verticalFanning:(CGFloat)verticalFanning {
  [self standardizeText:text
                   bold:bold
          respectHeight:respectHeight
               withFont:font
        verticalFanning:verticalFanning
         clipParagraphs:NO];
}

- (void)standardizeText:(NSString *)text bold:(BOOL)bold
          respectHeight:(BOOL)respectHeight
               withFont:(NSString *)font
        verticalFanning:(CGFloat)verticalFanning clipParagraphs:(BOOL)clipParagraphs {
  if ( [Utilities pureNil:text] ) {
    text = @"";
  }
#ifdef CLASSIC_SNAPPING
  self.text = text;
  
  if ( SYSTEM_VERSION_LESS_THAN(@"6.0") ) {
    if ( bold ) {
      self.font = [UIFont boldSystemFontOfSize:self.font.pointSize];
    } else {
      self.font = [UIFont systemFontOfSize:self.font.pointSize];
    }
  } else {
    NSString *fontName = font;
    self.font = [UIFont fontWithName:fontName
                                size:self.font.pointSize];
  }
  
  
  CGFloat bound = respectHeight ? self.frame.size.height : MAXFLOAT;
  CGSize s = [self.text sizeOfStringWithFont:self.font
                           constrainedToSize:CGSizeMake(self.frame.size.width,
                                                        bound)
                               lineBreakMode:NSLineBreakByWordWrapping];
  if ( [Utilities isIOS7] ) {
    
    s = CGSizeMake(ceilf(s.width), ceilf(s.height));
    
  }
  
  if ( (int)floor(s.height) % 2 != 0 ) {
    s.height = s.height+1.0;
  }
  
  self.frame = CGRectMake(self.frame.origin.x,
                          self.frame.origin.y,
                          self.frame.size.width,
                          s.height);
#else
  
  NSString *fontName = font;
  [self setFont:[UIFont fontWithName:fontName size:self.font.pointSize]];
  
  text = [Utilities stripTrailingNewline:text];
  
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  CGFloat ls = [Utilities isIOS7] ? 0.0 : 0.0;
  CGFloat modifier = [fontName rangeOfString:@"PTSerif"].location != NSNotFound ? 2.0 : 0.0;
  if ( ![Utilities isIOS7] ) {
    modifier += 1.0;
  }
  
  BOOL boldItalic = NO;
  if ( [fontName rangeOfString:@"Italic"].location != NSNotFound ) {
    ls = 3.0;
    if ( [font rangeOfString:@"BoldItalic"].location != NSNotFound ) {
      boldItalic = YES;
    }
  }
  
  if ( verticalFanning > 0.0 ) {
    ls = verticalFanning;
    modifier = verticalFanning+1.0;
  }
  
  [style setLineSpacing:ls];
  [style setMaximumLineHeight:self.font.pointSize+modifier];
  [style setMinimumLineHeight:self.font.pointSize+modifier];
  
  if ( clipParagraphs ) {
    if ( [Utilities isLandscape] ) {
      [style setParagraphSpacing:-7.0];
    } else {
      [style setParagraphSpacing:1.0];
    }
  } else {
    [style setParagraphSpacing:1.0];
  }
  
  if ( verticalFanning > 0.0 ) {
    [style setLineBreakMode:self.lineBreakMode];
  } else {
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
  }
  [style setAlignment:self.textAlignment];
  
  NSAttributedString *str = [[NSAttributedString alloc] initWithString:text
                                                            attributes:@{ NSParagraphStyleAttributeName : style}];
  self.attributedText = str;
  
  if ( respectHeight ) {
    CGSize s = [Utilities isIOS7] ? [str.string sizeOfStringWithFont:self.font
                                                   constrainedToSize:CGSizeMake(self.frame.size.width,MAXFLOAT)] :
    [str.string sizeOfStringWithFont:self.font
                   constrainedToSize:CGSizeMake(self.frame.size.width,MAXFLOAT)
                       lineBreakMode:NSLineBreakByTruncatingTail];
    
    CGFloat heightToUse = s.height;
    CGFloat approximateNumberOfLines = self.numberOfLines;
    
    BOOL squish = NO;
    if ( approximateNumberOfLines == 0 ) {
      approximateNumberOfLines = ceilf(self.frame.size.height/self.font.pointSize);
      squish = YES;
    }
    
    
    //heightToUse = s.height > self.frame.size.height ? self.font.pointSize*approximateNumberOfLines+2.0 : s.height;
    heightToUse = self.font.pointSize*approximateNumberOfLines+2.0;
    heightToUse = fminf(heightToUse, s.height);
    if ( squish ) {
      CGFloat multiplier = [Utilities isIOS7] ? 0.05 : 0.03;
      CGFloat ps = approximateNumberOfLines*(floorf(self.font.pointSize * multiplier));
      heightToUse -= ps;
    }
    
    if ( ![Utilities isIOS7] ) {
      if ( heightToUse < self.font.pointSize ) {
        CGFloat multiplier = [fontName rangeOfString:@"Lato-Light"].location != NSNotFound ? .07 : .05;
        heightToUse = ceilf(self.font.pointSize + (self.font.pointSize*multiplier));
      }
    }
    
    CGFloat bump = boldItalic ? 2.0 : 0.0;
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width+3.0,
                            heightToUse+bump);
  }
#endif
#ifdef FILL_BOUNDARIES
  [self fill];
#endif
}
- (void)standardizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight withFont:(NSString*)font {
  [self standardizeText:text bold:bold respectHeight:respectHeight withFont:font verticalFanning:0.0];
}

- (void)modText:(NSString*)text bold:(BOOL)bold {
  
  if ( SYSTEM_VERSION_LESS_THAN(@"6.0") ) {
    self.font = [UIFont systemFontOfSize:self.font.pointSize];
  } else {
    NSString *fontName = bold ? @"PTSerif-Bold" : @"PTSerif-Regular";
    self.font = [UIFont fontWithName:fontName
                                size:self.font.pointSize];
  }
  
  NSMutableAttributedString *str = [[NSMutableAttributedString alloc]
                                    initWithString:text];
  
  NSMutableParagraphStyle *mutParaStyle=[[NSMutableParagraphStyle alloc] init];
  
  [mutParaStyle setAlignment:NSTextAlignmentJustified];
  
  [str addAttributes:[NSDictionary dictionaryWithObject:mutParaStyle
                                                 forKey:NSParagraphStyleAttributeName]
               range:NSMakeRange(0,[[str string] length])];
  
  self.attributedText = str;
  
  CGSize s = [self.attributedText.string sizeOfStringWithFont:self.font
                   constrainedToSize:CGSizeMake(self.frame.size.width,
                                                self.frame.size.height)];
  CGFloat heightToUse = s.height > self.frame.size.height ? self.frame.size.height : s.height;
  
  self.frame = CGRectMake(self.frame.origin.x,
                          self.frame.origin.y,
                          self.frame.size.width,
                          heightToUse);
  
  
  self.lineBreakMode = NSLineBreakByTruncatingTail;
}

- (void)headlineSnap:(NSString *)text respectHeight:(BOOL)respectHeight {
  [self snapText:text bold:YES respectHeight:respectHeight];
  self.textColor = [[DesignManager shared] darkoalColor];

}

- (void)bodytextSnap:(NSString *)text respectHeight:(BOOL)respectHeight {
  [self snapText:text bold:NO respectHeight:respectHeight];
  self.textColor = [[DesignManager shared] offwhiteColor];
}

- (NSInteger)decentCharLimitForMe {
 

  NSString *k = @"";
  while ( [k length] < 1000000 ) {
    
    CGSize s = [k sizeOfStringWithFont:self.font
                     constrainedToSize:CGSizeMake(self.frame.size.width,
                                                  self.frame.size.height)];
    
    CGFloat val = abs(s.height - self.frame.size.height);
    if ( val <= 2.0 ) {
      

      return [k length];
    }
    
    if ( [k length] % 2 == 0 ) {
      k = [k stringByAppendingString:@"A"];
    } else {
      k = [k stringByAppendingString:@"a"];
    }
    
  }
  

  
  return 300;
  
}

- (void)kernedBodytextSnap:(NSString *)text respectHeight:(BOOL)respectHeight {
  [self modText:text bold:NO];
  self.textColor = [[DesignManager shared] offwhiteColor];
}

- (void)modText:(NSString *)text {
  [self modText:text bold:NO];
}

- (void)emboss {
  self.shadowColor = [[DesignManager shared] steamColor];
  self.shadowOffset = CGSizeMake(0.0,1.0);
}

- (void)extrude {
  self.shadowColor = [[DesignManager shared] obsidianColor:0.5];
  self.shadowOffset = CGSizeMake(0.0,1.0);
}

@end
