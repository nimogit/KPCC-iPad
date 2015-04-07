//
//  SCPRStoryTableViewCell.h
//  KPCC
//
//  Created by Ben Hochberg on 4/7/15.
//  Copyright (c) 2015 scpr. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCPRGrayLineView;

@interface SCPRStoryTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView *contentSeatView;
@property (nonatomic, strong) IBOutlet UILabel *headlineCaptionLabel;
@property (nonatomic, strong) IBOutlet UIView *quantityView;
@property (nonatomic, strong) IBOutlet UIView *blackStripeView;
@property (nonatomic, strong) IBOutlet UILabel *quantityLabel;
@property (nonatomic, strong) IBOutlet SCPRGrayLineView *grayLineView;
@property (nonatomic, strong) IBOutlet UILabel *blurbLabel;
@property (nonatomic, strong) IBOutlet UILabel *readMoreLabel;
@property (nonatomic, strong) IBOutlet UIButton *readMoreButton;

- (void)setupWithStory:(NSDictionary*)story;
- (void)applyQuantity:(NSInteger)quantity;

@end
