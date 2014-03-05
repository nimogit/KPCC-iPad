//
//  SCPRCompBaseCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 8/20/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRCompBaseCell.h"
#import "SCPRCompositeCellViewController.h"

@implementation SCPRCompBaseCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BOOL)isLocked {
  for ( SCPRCompositeCellViewController *cell in self.articleFacades ) {
    if ( cell.locked ) {
      return YES;
    }
  }
  
  return NO;
}

@end
