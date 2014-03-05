//
//  SCPREventCell.h
//  KPCC
//
//  Created by Hochberg, Ben on 6/12/13.
//  Copyright (c) 2013 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPREventCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UIImageView *eventImage;
@property (nonatomic,strong) IBOutlet UILabel *eventDateLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventTitleLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventDescriptionLabel;
@property (nonatomic,strong) IBOutlet UILabel *eventLocationLabel;


- (void)primeCell:(NSDictionary*)event;

@end
