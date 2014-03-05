//
//  SCPRBlankCell.m
//  KPCC
//
//  Created by Hochberg, Ben on 10/31/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import "SCPRBlankCell.h"

@implementation SCPRBlankCell

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

@end
