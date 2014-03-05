//
//  SCPRCandidateCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 9/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRCandidateCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UIButton *thatsMeButton;
@property (nonatomic,strong) IBOutlet UILabel *nameLabel;
@property (nonatomic,strong) IBOutlet UILabel *IDLabel;

@end
