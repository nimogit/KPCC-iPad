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
  
  [self.headlineCaptionLabel titleizeText:story[@"headline"]
                           bold:NO
                  respectHeight:YES
                        lighten:YES];
  
  [self.blurbLabel snapText:[Utilities unwebbifyString:story[@"summary"]]
                       bold:NO];
  
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
  
}

- (void)applyQuantity:(NSInteger)quantity {
  self.quantityLabel.text = [NSString stringWithFormat:@"%ld Stories",(long)quantity];
  
  [self.quantityLabel italicizeText:self.quantityLabel.text
                               bold:NO
                      respectHeight:YES];
  
  
}

@end
