//
//  NSString+sizeWithFont.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "NSString+sizeWithFont.h"
#import "Utilities.h"

@implementation NSString (sizeWithFont)


- (CGSize)sizeOfStringWithFont:(UIFont *)font {
  return [self sizeOfStringWithFont:font constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (CGSize)sizeOfStringWithFont:(UIFont *)font constrainedToSize:(CGSize)size {
  return [self sizeOfStringWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)sizeOfStringWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode {
  
  if ( [Utilities isIOS7] ) {
  
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:size];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.length)];
    [textContainer setLineBreakMode:lineBreakMode];
    [textContainer setLineFragmentPadding:0.0];
    (void)[layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size;
    
  }
  
  return [self sizeWithFont:font
          constrainedToSize:size
              lineBreakMode:lineBreakMode];
}

@end
