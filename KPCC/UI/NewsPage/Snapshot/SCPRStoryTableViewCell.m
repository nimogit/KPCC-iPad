//
//  SCPRStoryTableViewCell.m
//  KPCC
//
//  Created by Ben Hochberg on 4/7/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import "SCPRStoryTableViewCell.h"
#import "UILabel+Adjustments.h"
#import "SCPRGrayLineView.h"
#import "Utilities.h"

@implementation SCPRStoryTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSString*)reuseIdentifier {
  return @"story-cell";
}

- (void)setupWithStory:(NSDictionary *)story {
  self.grayLineView.vertical = YES;
  
  
  NSString *headline = story[@"headline"];
  [self.headlineCaptionLabel titleizeText:headline
                           bold:NO
                  respectHeight:YES
                        lighten:YES];
  
  NSString *summary = story[@"summary"];
  summary = [Utilities unwebbifyString:summary];
  summary = [summary trimLeadingWhitespace];
  
  NSLog(@"Blurb Height before text : %1.1f",self.blurbLabel.frame.size.height);
  if ( ![Utilities isIOS7] ) {
    [self.blurbLabel snapText:summary
                       bold:NO];
  } else {
    self.blurbLabel.font = [[DesignManager shared] bodyFontRegular:16.0f];
    self.blurbLabel.text = summary;
  }

  
  self.readMoreLabel.textColor = [[DesignManager shared] turquoiseCrystalColor:1.0];
  NSString *moreLabelString = @"";
  if ( [[ContentManager shared] isKPCCArticle:story] ) {

    moreLabelString = @"Read it on KPCC";
  
  } else {
    NSString *source = [story objectForKey:@"source"];
    moreLabelString = [NSString stringWithFormat:@"Read it on %@",source];
  }
  
  [self.readMoreLabel titleizeText:moreLabelString
                              bold:NO
                     respectHeight:YES
                           lighten:NO];

  
  [self.headlineCaptionLabel layoutIfNeeded];
  [self.blurbLabel layoutIfNeeded];
  [self.contentView layoutSubviews];

  NSLog(@"Blurb Height after text : %1.1f",self.blurbLabel.frame.size.height);
  
  self.topAlignmentAnchor.constant = 4.0f;
}

- (void)applyQuantity:(NSInteger)quantity {
  self.quantityLabel.text = [NSString stringWithFormat:@"%ld Stories",(long)quantity];
  
  [self.quantityLabel italicizeText:self.quantityLabel.text
                               bold:NO
                      respectHeight:YES];
  
  
}

- (CGFloat)heightGuess {
  [self.contentView layoutSubviews];
  NSString *text = self.blurbLabel.text;
  CGSize s = [text sizeOfStringWithFont:self.blurbLabel.font
                      constrainedToSize:CGSizeMake(self.blurbLabel.frame.size.width,
                                                   MAXFLOAT)];
  
  CGFloat guess = self.blurbLabel.frame.origin.y + s.height + 10.0f + self.readMoreLabel.frame.size.height;
  NSLog(@"Height Guess : %1.1f",guess);
  return guess;
}

- (void)prepareForReuse {
  [self.linkArrowImage layoutIfNeeded];
  [self.contentSeatView layoutIfNeeded];
}

@end
