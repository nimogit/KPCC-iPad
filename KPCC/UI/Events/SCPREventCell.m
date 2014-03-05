//
//  SCPREventCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPREventCell.h"
#import "global.h"

@implementation SCPREventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)primeCell:(NSDictionary*)event {
  
  self.eventDateLabel.textColor = [[DesignManager shared] softBlueColor];
  self.eventTitleLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  self.eventDescriptionLabel.textColor = [[DesignManager shared] vinylColor:1.0];
  self.eventLocationLabel.textColor = [[DesignManager shared] kpccDarkOrangeColor];
  
  [self.eventDateLabel emboss];
  [self.eventTitleLabel emboss];
  [self.eventDescriptionLabel emboss];
  [self.eventLocationLabel emboss];
  
  self.backgroundColor = [[DesignManager shared] number1pencilColor];
  
  [self.eventDateLabel snapText:[Utilities prettyStringFromRFCDateString:[event objectForKey:@"starts_at"]]
                           bold:NO
                  respectHeight:YES];
  
  [self.eventTitleLabel snapText:[event objectForKey:@"title"]
                            bold:YES
                   respectHeight:YES];
  
  [self.eventDescriptionLabel snapText:[event objectForKey:@"teaser"]
                                  bold:NO
                         respectHeight:YES];
  
  NSDictionary *location = [event objectForKey:@"location"];
  [self.eventLocationLabel snapText:[location objectForKey:@"title"]
                               bold:NO];
  
  NSString *image = [Utilities extractImageURLFromBlob:event quality:AssetQualitySmall];
  self.eventImage.clipsToBounds = YES;
  if ( !image ) {
    self.eventImage.image = [UIImage imageNamed:@"kpcc-twitter-logo.png"];
  } else {
    [self.eventImage loadImage:image];
  }
  
  
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
