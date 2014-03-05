//
//  SCPRProfileReminderCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 6/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRProfileReminderCell.h"

@implementation SCPRProfileReminderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if ( self ) {
    self.programImageView.clipsToBounds = YES;
  }
  
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {

}

- (NSString*)reuseIdentifier {
  return @"reminder_cell";
}

@end
