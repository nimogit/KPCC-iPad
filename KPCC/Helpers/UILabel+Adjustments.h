//
//  UILabel+Adjustments.h
//  KPCC
//
//  Created by Ben Hochberg on 4/22/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "global.h"



@interface UILabel (Adjustments)


- (void)snapText:(NSString*)text bold:(BOOL)bold;
- (void)snapText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight;
- (void)modText:(NSString*)text;
- (void)modText:(NSString *)text bold:(BOOL)bold;
- (void)headlineSnap:(NSString*)text respectHeight:(BOOL)respectHeight;
- (void)bodytextSnap:(NSString*)text respectHeight:(BOOL)respectHeight;
- (void)kernedBodytextSnap:(NSString*)text respectHeight:(BOOL)respectHeight;
- (void)emboss;
- (void)extrude;
- (void)titleizeText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight;
- (void)titleizeText:(NSString*)text bold:(BOOL)bold contain:(CGRect)contain;
- (void)titleizeText:(NSString *)text bold:(BOOL)bold;
- (void)titleizeText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight lighten:(BOOL)lighten;

- (void)standardizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight withFont:(NSString *)font verticalFanning:(CGFloat)verticalFanning;
- (void)standardizeText:(NSString *)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight withFont:(NSString *)font verticalFanning:(CGFloat)verticalFanning clipParagraphs:(BOOL)clipParagraphs;

- (void)standardizeText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight withFont:(NSString*)font;
- (void)italicizeText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight;
- (void)thickerText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight;
- (void)sansifyTitleText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight;
- (void)sansifyTitleText:(NSString*)text bold:(BOOL)bold respectHeight:(BOOL)respectHeight centered:(BOOL)centered;
- (NSInteger)decentCharLimitForMe;
- (void)fill;

- (NSInteger)approximateNumberOfLines;

@end
