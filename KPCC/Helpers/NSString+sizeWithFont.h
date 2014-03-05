//
//  NSString+sizeWithFont.h
//  KPCC
//
//  Created by Hochberg, Ben on 8/29/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (sizeWithFont)

- (CGSize)sizeOfStringWithFont:(UIFont*)font;
- (CGSize)sizeOfStringWithFont:(UIFont*)font constrainedToSize:(CGSize)size;
- (CGSize)sizeOfStringWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end
