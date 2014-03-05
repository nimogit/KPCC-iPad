//
//  SCPRProfileReminderCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/24/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPRProfileReminderCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UIImageView *programImageView;
@property (nonatomic,strong) IBOutlet UILabel *programTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *remindMeLabel;
@property (nonatomic,strong) IBOutlet UISwitch *remindMeSwitch;


@end
